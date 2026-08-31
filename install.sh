#!/bin/sh

set -eu

repo_url=${AGENTS_REPO_URL:-https://github.com/schalk-conradie/skills.git}
agents_dir=${AGENTS_DIR:-"$HOME/.agents"}
force=0

usage() {
  cat <<'EOF'
Usage: install.sh [--repo URL] [--force]

Clone the personal agent configuration into ~/.agents and create these links:
  ~/.codex/AGENTS.md   -> ~/.agents/AGENTS.md
  ~/.claude/CLAUDE.md  -> ~/.agents/CLAUDE.md
  ~/.claude/skills/*   -> ~/.agents/skills/personal/*

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
elif [ -e "$agents_dir" ]; then
  if [ -n "$(find "$agents_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    fail "$agents_dir exists and is not a Git repository"
  fi
  git clone "$repo_url" "$agents_dir"
else
  git clone "$repo_url" "$agents_dir"
fi

agents_source="$agents_dir/AGENTS.md"
claude_source="$agents_dir/CLAUDE.md"
skills_source="$agents_dir/skills/personal"

[ -f "$agents_source" ] || fail "missing source file: $agents_source"
[ -f "$claude_source" ] || fail "missing source file: $claude_source"
[ -d "$skills_source" ] || fail "missing skills directory: $skills_source"

canonical_file() {
  file_dir=$(dirname "$1")
  file_name=$(basename "$1")
  printf '%s/%s\n' "$(cd "$file_dir" && pwd -P)" "$file_name"
}

link_matches() {
  source_path=$(canonical_file "$1")
  target_path=$2

  if [ -L "$target_path" ]; then
    link_value=$(readlink "$target_path")
    case "$link_value" in
      /*) resolved_path=$link_value ;;
      *) resolved_path=$(dirname "$target_path")/$link_value ;;
    esac
    resolved_dir=$(dirname "$resolved_path")
    resolved_name=$(basename "$resolved_path")
    [ -d "$resolved_dir" ] || return 1
    resolved_path=$(printf '%s/%s' "$(cd "$resolved_dir" && pwd -P)" "$resolved_name")
    [ "$resolved_path" = "$source_path" ]
    return
  fi

  [ -e "$target_path" ] && [ "$source_path" -ef "$target_path" ]
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
  resolved_name=$(basename "$resolved_path")
  [ -d "$resolved_dir" ] || return 1
  printf '%s/%s\n' "$(cd "$resolved_dir" && pwd -P)" "$resolved_name"
}

preflight_target() {
  source_path=$1
  target_path=$2

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    if link_matches "$source_path" "$target_path"; then
      return
    fi
    [ "$force" -eq 1 ] || fail "$target_path already exists; rerun with --force to back it up and replace it"
  fi
}

install_link() {
  source_path=$(canonical_file "$1")
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

  ln -s "$source_path" "$target_path"
  printf 'Created link: %s -> %s\n' "$target_path" "$source_path"
}

remove_stale_skill_links() {
  source_root=$(canonical_file "$1")
  target_root=$2

  [ -d "$target_root" ] || return
  for target_path in "$target_root"/*; do
    [ -L "$target_path" ] || continue
    resolved_path=$(resolve_link_target "$target_path") || continue
    case "$resolved_path" in
      "$source_root"/*)
        if [ ! -f "$resolved_path/SKILL.md" ]; then
          rm "$target_path"
          printf 'Removed stale skill link: %s\n' "$target_path"
        fi
        ;;
    esac
  done
}

codex_target="$HOME/.codex/AGENTS.md"
claude_target="$HOME/.claude/CLAUDE.md"
claude_skills="$HOME/.claude/skills"

preflight_target "$agents_source" "$codex_target"
preflight_target "$claude_source" "$claude_target"

skills_found=0
for skill_source in "$skills_source"/*; do
  [ -d "$skill_source" ] || continue
  [ -f "$skill_source/SKILL.md" ] || continue
  skills_found=1
  skill_name=$(basename "$skill_source")
  preflight_target "$skill_source" "$claude_skills/$skill_name"
done
[ "$skills_found" -eq 1 ] || fail "no skills found in $skills_source"

mkdir -p "$HOME/.codex" "$HOME/.claude" "$claude_skills"
install_link "$agents_source" "$codex_target"
install_link "$claude_source" "$claude_target"

for skill_source in "$skills_source"/*; do
  [ -d "$skill_source" ] || continue
  [ -f "$skill_source/SKILL.md" ] || continue
  skill_name=$(basename "$skill_source")
  install_link "$skill_source" "$claude_skills/$skill_name"
done

remove_stale_skill_links "$skills_source" "$claude_skills"

printf 'Agent configuration is ready. Edit shared files in %s.\n' "$agents_dir"
