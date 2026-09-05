# Bootstrap ~/.agents on Windows (PowerShell 7 or Windows PowerShell 5.1). install.sh does the same on macOS and Linux.
# Everything canonical lives in ~/.agents; every other location only receives links.

[CmdletBinding()]
param(
    [string]$RepoUrl = $(if ($env:AGENTS_REPO_URL) { $env:AGENTS_REPO_URL } else { "https://github.com/schalk-conradie/skills.git" }),
    [string]$AgentsDir = $(if ($env:AGENTS_DIR) { $env:AGENTS_DIR } else { Join-Path $HOME ".agents" }),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Harness adapters. A row is applied only when the home dir exists. Harnesses that already scan
# ~/.agents/skills (Codex, Cursor, Grok, OpenCode, Copilot) leave Skills empty.
$harnessTable = @(
    @{ Home = ".claude"; Instructions = "CLAUDE.md"; Skills = "skills" }
    @{ Home = ".codex"; Instructions = "AGENTS.md"; Skills = "" }
)

function Resolve-LinkTarget {
    param([System.IO.FileSystemInfo]$Item)

    if ($Item.LinkType -notin @("SymbolicLink", "Junction")) {
        return $null
    }
    $linkTarget = [string]$Item.Target
    if (-not [IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = Join-Path (Split-Path -Parent $Item.FullName) $linkTarget
    }
    return [IO.Path]::GetFullPath($linkTarget)
}

function Test-LinkMatches {
    param([string]$Source, [string]$Target)

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }
    $sourcePath = [IO.Path]::GetFullPath($Source)
    if ($item.LinkType -in @("SymbolicLink", "Junction")) {
        return (Resolve-LinkTarget -Item $item) -eq $sourcePath
    }
    if ($item.LinkType -eq "HardLink" -and -not $item.PSIsContainer) {
        return (Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Source).Hash
    }
    return $false
}

function Assert-TargetAvailable {
    param([string]$Source, [string]$Target)

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item -and -not (Test-LinkMatches -Source $Source -Target $Target) -and -not $Force) {
        throw "$Target already exists. Rerun with -Force to back it up and replace it."
    }
}

function Install-PathLink {
    param([string]$Source, [string]$Target)

    if (Test-LinkMatches -Source $Source -Target $Target) {
        Write-Host "Link already correct: $Target"
        return
    }
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item) {
        $backup = "$Target.backup.$(Get-Date -Format 'yyyyMMddHHmmss').$PID"
        Move-Item -LiteralPath $Target -Destination $backup
        Write-Host "Backed up conflict: $backup"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    $isDirectory = Test-Path -LiteralPath $Source -PathType Container
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "Created link: $Target -> $Source"
    }
    catch {
        try {
            $fallbackType = if ($isDirectory) { "Junction" } else { "HardLink" }
            New-Item -ItemType $fallbackType -Path $Target -Target $Source -ErrorAction Stop | Out-Null
            Write-Warning "Symbolic links are not permitted, so a $fallbackType was created instead: $Target"
            Write-Warning "Enable Windows Developer Mode and rerun with -Force to replace it with a symbolic link."
        }
        catch {
            throw "Could not link $Target to $Source. Enable Windows Developer Mode or run PowerShell as Administrator."
        }
    }
}

# Remove links in TargetRoot that point into SourceRoot but no longer resolve to a skill
# directory. Links owned by other tools are left alone.
function Remove-StaleLinks {
    param([string]$TargetRoot, [string]$SourceRoot)

    if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
        return
    }
    $sourceRootPath = [IO.Path]::GetFullPath($SourceRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $comparison = if ($env:OS -eq "Windows_NT") { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    foreach ($entry in Get-ChildItem -LiteralPath $TargetRoot -Force) {
        $resolved = Resolve-LinkTarget -Item $entry
        if (-not $resolved -or -not $resolved.StartsWith($sourceRootPath, $comparison)) {
            continue
        }
        $stale = -not (Test-Path -LiteralPath $resolved -PathType Container) -or
            -not (Test-Path -LiteralPath (Join-Path $resolved "SKILL.md") -PathType Leaf)
        if ($stale) {
            if ($entry.PSIsContainer) {
                # Delete only the directory link, without PowerShell 5.1's child-item prompt.
                [IO.Directory]::Delete($entry.FullName)
            }
            else {
                Remove-Item -LiteralPath $entry.FullName -Force
            }
            Write-Host "Removed stale link: $($entry.FullName)"
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required."
}

if (Test-Path -LiteralPath (Join-Path $AgentsDir ".git") -PathType Container) {
    Write-Host "Using existing repository: $AgentsDir"
}
elseif ((Test-Path -LiteralPath $AgentsDir) -and (Get-ChildItem -LiteralPath $AgentsDir -Force | Select-Object -First 1)) {
    throw "$AgentsDir exists and is not a Git repository."
}
else {
    & git clone -- $RepoUrl $AgentsDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE" }
}

$instructionsSource = Join-Path $AgentsDir "AGENTS.md"
$skillsSource = Join-Path $AgentsDir "skills/personal"
if (-not (Test-Path -LiteralPath $instructionsSource -PathType Leaf)) { throw "Missing source file: $instructionsSource" }
if (-not (Test-Path -LiteralPath $skillsSource -PathType Container)) { throw "Missing skills directory: $skillsSource" }

$skillSources = @(
    Get-ChildItem -LiteralPath $skillsSource -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") -PathType Leaf } |
        Sort-Object Name
)
if ($skillSources.Count -eq 0) { throw "No skills found in $skillsSource" }

# Every link to manage, built once and applied in two passes: preflight, then install.
$plan = [System.Collections.Generic.List[object]]::new()
foreach ($skill in $skillSources) {
    $plan.Add(@{ Source = $skill.FullName; Target = Join-Path (Join-Path $AgentsDir "skills") $skill.Name })
}
$activeHarnesses = @($harnessTable | Where-Object { Test-Path -LiteralPath (Join-Path $HOME $_.Home) -PathType Container })
foreach ($harness in $activeHarnesses) {
    $harnessHome = Join-Path $HOME $harness.Home
    if ($harness.Instructions) {
        $plan.Add(@{ Source = $instructionsSource; Target = Join-Path $harnessHome $harness.Instructions })
    }
    if ($harness.Skills) {
        foreach ($skill in $skillSources) {
            $plan.Add(@{ Source = $skill.FullName; Target = Join-Path (Join-Path $harnessHome $harness.Skills) $skill.Name })
        }
    }
}

foreach ($link in $plan) {
    Assert-TargetAvailable -Source $link.Source -Target $link.Target
}
foreach ($link in $plan) {
    Install-PathLink -Source $link.Source -Target $link.Target
}

Remove-StaleLinks -TargetRoot (Join-Path $AgentsDir "skills") -SourceRoot $skillsSource
foreach ($harness in $activeHarnesses) {
    $harnessHome = Join-Path $HOME $harness.Home
    if ($harness.Skills) { Remove-StaleLinks -TargetRoot (Join-Path $harnessHome $harness.Skills) -SourceRoot $skillsSource }
}

Write-Host "Agent configuration is ready. Edit shared files in $AgentsDir."
