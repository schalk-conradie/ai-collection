#!/bin/sh

# Bootstrap ~/.agents on macOS or Linux. install.ps1 does the same on Windows.
# Everything canonical lives in ~/.agents; every other location only receives links.

set -eu

repo_url=${AGENTS_REPO_URL:-https://github.com/schalk-conradie/skills.git}
agents_dir=${AGENTS_DIR:-"$HOME/.agents"}
force=0

# Harness adapters, one per line: <home dir under ~> <instructions file or -> <skills dir or ->
# A line is applied only when the home dir exists. Harnesses that already scan ~/.agents/skills
# (Codex, Cursor, Grok, OpenCode, Copilot) get "-" for skills.
harness_table='
.claude CLAUDE.md skills
.codex AGENTS.md -
'

usage() {
  cat <<'EOF'
Usage: install.sh [--repo URL] [--force]

Clone the personal agent configuration into ~/.agents, then link:
  ~/.agents/skills/<name>   -> ~/.agents/skills/personal/<name>   (every skill, read by all harnesses)
  ~/.claude/CLAUDE.md       -> ~/.agents/AGENTS.md                 (when ~/.claude exists)
  ~/.claude/skills/<name>   -> ~/.agents/skills/personal/<name>    (when ~/.claude exists)
  ~/.codex/AGENTS.md        -> ~/.agents/AGENTS.md                 (when ~/.codex exists)

Options:
  --repo URL  Clone a different Git remote.
  --force     Back up conflicting target files before replacing them.
  -h, --help  Show this help.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || fail "--repo requires a URL"
      repo_url=$2
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

command -v git >/dev/null 2>&1 || fail "Git is required"

if [ -d "$agents_dir/.git" ]; then
  printf 'Using existing repository: %s\n' "$agents_dir"
elif [ -e "$agents_dir" ] && [ -n "$(find "$agents_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
  fail "$agents_dir exists and is not a Git repository"
else
  git clone "$repo_url" "$agents_dir"
fi

instructions_source="$agents_dir/AGENTS.md"
skills_source="$agents_dir/skills/personal"

[ -f "$instructions_source" ] || fail "missing source file: $instructions_source"
[ -d "$skills_source" ] || fail "missing skills directory: $skills_source"

canonical_path() {
  file_dir=$(dirname "$1")
  file_name=$(basename "$1")
  printf '%s/%s\n' "$(cd "$file_dir" && pwd -P)" "$file_name"
}

resolve_link_target() {
  target_path=$1
  [ -L "$target_path" ] || return 1
  link_value=$(readlink "$target_path")
  case "$link_value" in
    /*) resolved_path=$link_value ;;
    *) resolved_path=$(dirname "$target_path")/$link_value ;;
  esac
  resolved_dir=$(dirname "$resolved_path")
  [ -d "$resolved_dir" ] || return 1
  printf '%s/%s\n' "$(cd "$resolved_dir" && pwd -P)" "$(basename "$resolved_path")"
}

link_matches() {
  source_path=$(canonical_path "$1")
  target_path=$2
  if [ -L "$target_path" ]; then
    resolved_path=$(resolve_link_target "$target_path") || return 1
    [ "$resolved_path" = "$source_path" ]
    return
  fi
  [ -e "$target_path" ] && [ "$source_path" -ef "$target_path" ]
}

preflight_link() {
  source_path=$1
  target_path=$2
  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    link_matches "$source_path" "$target_path" && return
    [ "$force" -eq 1 ] || fail "$target_path already exists; rerun with --force to back it up and replace it"
  fi
}

install_link() {
  source_path=$(canonical_path "$1")
  target_path=$2
  if link_matches "$source_path" "$target_path"; then
    printf 'Link already correct: %s\n' "$target_path"
    return
  fi
  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_path="$target_path.backup.$(date +%Y%m%d%H%M%S).$$"
    mv "$target_path" "$backup_path"
    printf 'Backed up conflict: %s\n' "$backup_path"
  fi
  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  printf 'Created link: %s -> %s\n' "$target_path" "$source_path"
}

# Remove links in target_root that point into source_root but no longer resolve to a
# skill directory. Links owned by other tools are left alone.
remove_stale_links() {
  target_root=$1
  source_root=$(canonical_path "$2")
  [ -d "$target_root" ] || return 0
  for target_path in "$target_root"/* "$target_root"/.[!.]*; do
    [ -L "$target_path" ] || continue
    resolved_path=$(resolve_link_target "$target_path") || continue
    case "$resolved_path" in
      "$source_root"/*) ;;
      *) continue ;;
    esac
    if [ ! -d "$resolved_path" ] || [ ! -f "$resolved_path/SKILL.md" ]; then
      rm "$target_path"
      printf 'Removed stale link: %s\n' "$target_path"
    fi
  done
}

# Emit "source<TAB>target" for every link to manage. Called twice: preflight, then install.
plan_links() {
  for skill_source in "$skills_source"/*; do
    [ -f "$skill_source/SKILL.md" ] || continue
    printf '%s\t%s\n' "$skill_source" "$agents_dir/skills/$(basename "$skill_source")"
  done

  printf '%s\n' "$harness_table" | while read -r home_dir instructions_file skills_dir; do
    [ -n "$home_dir" ] || continue
    harness_home="$HOME/$home_dir"
    [ -d "$harness_home" ] || continue
    if [ "$instructions_file" != "-" ]; then
      printf '%s\t%s\n' "$instructions_source" "$harness_home/$instructions_file"
    fi
    if [ "$skills_dir" != "-" ]; then
      for skill_source in "$skills_source"/*; do
        [ -f "$skill_source/SKILL.md" ] || continue
        printf '%s\t%s\n' "$skill_source" "$harness_home/$skills_dir/$(basename "$skill_source")"
      done
    fi
  done
}

[ -n "$(plan_links)" ] || fail "no skills found in $skills_source"

tab=$(printf '\t')
plan_links | while IFS="$tab" read -r source_path target_path; do
  preflight_link "$source_path" "$target_path"
done

plan_links | while IFS="$tab" read -r source_path target_path; do
  install_link "$source_path" "$target_path"
done

remove_stale_links "$agents_dir/skills" "$skills_source"
printf '%s\n' "$harness_table" | while read -r home_dir instructions_file skills_dir; do
  [ -n "$home_dir" ] && [ -d "$HOME/$home_dir" ] || continue
  [ "$skills_dir" = "-" ] || remove_stale_links "$HOME/$home_dir/$skills_dir" "$skills_source"
done

printf 'Agent configuration is ready. Edit shared files in %s.\n' "$agents_dir"
