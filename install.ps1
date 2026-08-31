[CmdletBinding()]
param(
    [string]$RepoUrl = $(if ($env:AGENTS_REPO_URL) { $env:AGENTS_REPO_URL } else { "https://github.com/schalk-conradie/skills.git" }),
    [string]$AgentsDir = $(if ($env:AGENTS_DIR) { $env:AGENTS_DIR } else { Join-Path $HOME ".agents" }),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Resolve-LinkTarget {
    param(
        [System.IO.FileSystemInfo]$Item,
        [string]$Target
    )

    if ($Item.LinkType -notin @("SymbolicLink", "Junction")) {
        return $null
    }

    $linkTarget = [string]$Item.Target
    if (-not [IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = Join-Path (Split-Path -Parent $Target) $linkTarget
    }
    return [IO.Path]::GetFullPath($linkTarget)
}

function Test-LinkMatches {
    param(
        [string]$Source,
        [string]$Target
    )

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }

    $sourcePath = [IO.Path]::GetFullPath($Source)
    if ($item.LinkType -in @("SymbolicLink", "Junction")) {
        return (Resolve-LinkTarget -Item $item -Target $Target) -eq $sourcePath
    }

    if ($item.LinkType -eq "HardLink" -and -not $item.PSIsContainer) {
        return (Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Source).Hash
    }

    return $false
}

function Assert-TargetAvailable {
    param(
        [string]$Source,
        [string]$Target
    )

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item -and -not (Test-LinkMatches -Source $Source -Target $Target) -and -not $Force) {
        throw "$Target already exists. Rerun with -Force to back it up and replace it."
    }
}

function Install-PathLink {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$Directory
    )

    if (Test-LinkMatches -Source $Source -Target $Target) {
        Write-Host "Link already correct: $Target"
        return
    }

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item) {
        $stamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "$Target.backup.$stamp.$PID"
        Move-Item -LiteralPath $Target -Destination $backup
        Write-Host "Backed up conflict: $backup"
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "Created symbolic link: $Target -> $Source"
    }
    catch {
        try {
            $fallbackType = if ($Directory) { "Junction" } else { "HardLink" }
            New-Item -ItemType $fallbackType -Path $Target -Target $Source -ErrorAction Stop | Out-Null
            Write-Warning "Windows denied a symbolic link, so the installer created a $fallbackType link: $Target"
            Write-Warning "Enable Windows Developer Mode and rerun with -Force if you prefer a symbolic link."
        }
        catch {
            throw "Could not link $Target to $Source. Enable Windows Developer Mode or run PowerShell as Administrator."
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required."
}

$gitDirectory = Join-Path $AgentsDir ".git"
if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
    Write-Host "Using existing repository: $AgentsDir"
}
elseif (Test-Path -LiteralPath $AgentsDir) {
    $firstEntry = Get-ChildItem -LiteralPath $AgentsDir -Force | Select-Object -First 1
    if ($firstEntry) {
        throw "$AgentsDir exists and is not a Git repository."
    }
    & git clone -- $RepoUrl $AgentsDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE" }
}
else {
    & git clone -- $RepoUrl $AgentsDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE" }
}

$agentsSource = Join-Path $AgentsDir "AGENTS.md"
$claudeSource = Join-Path $AgentsDir "CLAUDE.md"
$skillsSource = Join-Path $AgentsDir "skills/personal"
if (-not (Test-Path -LiteralPath $agentsSource -PathType Leaf)) { throw "Missing source file: $agentsSource" }
if (-not (Test-Path -LiteralPath $claudeSource -PathType Leaf)) { throw "Missing source file: $claudeSource" }
if (-not (Test-Path -LiteralPath $skillsSource -PathType Container)) { throw "Missing skills directory: $skillsSource" }

$codexDirectory = Join-Path $HOME ".codex"
$claudeDirectory = Join-Path $HOME ".claude"
$claudeSkills = Join-Path $claudeDirectory "skills"
$codexTarget = Join-Path $codexDirectory "AGENTS.md"
$claudeTarget = Join-Path $claudeDirectory "CLAUDE.md"
$skillSources = @(
    Get-ChildItem -LiteralPath $skillsSource -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") -PathType Leaf } |
        Sort-Object Name
)
if ($skillSources.Count -eq 0) { throw "No skills found in $skillsSource" }

Assert-TargetAvailable -Source $agentsSource -Target $codexTarget
Assert-TargetAvailable -Source $claudeSource -Target $claudeTarget
foreach ($skillSource in $skillSources) {
    Assert-TargetAvailable -Source $skillSource.FullName -Target (Join-Path $claudeSkills $skillSource.Name)
}

New-Item -ItemType Directory -Path $codexDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $claudeDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $claudeSkills -Force | Out-Null
Install-PathLink -Source $agentsSource -Target $codexTarget
Install-PathLink -Source $claudeSource -Target $claudeTarget
foreach ($skillSource in $skillSources) {
    Install-PathLink -Source $skillSource.FullName -Target (Join-Path $claudeSkills $skillSource.Name) -Directory
}

$skillsRootPath = [IO.Path]::GetFullPath($skillsSource).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
) + [IO.Path]::DirectorySeparatorChar
$comparison = if ($env:OS -eq "Windows_NT") {
    [StringComparison]::OrdinalIgnoreCase
}
else {
    [StringComparison]::Ordinal
}
foreach ($entry in Get-ChildItem -LiteralPath $claudeSkills -Force) {
    $resolvedTarget = Resolve-LinkTarget -Item $entry -Target $entry.FullName
    if (-not $resolvedTarget -or -not $resolvedTarget.StartsWith($skillsRootPath, $comparison)) {
        continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedTarget "SKILL.md") -PathType Leaf)) {
        Remove-Item -LiteralPath $entry.FullName -Force
        Write-Host "Removed stale skill link: $($entry.FullName)"
    }
}

Write-Host "Agent configuration is ready. Edit shared files in $AgentsDir."
