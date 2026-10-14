#!/usr/bin/env bash
# Remove a skill from skills/ (in whatever category it lives) and its row from the AGENTS.md table.
#
# Usage:
#   scripts/remove.sh [-n|--dry-run] [-y|--yes] <skill>
#
# Works for vendored and personal skills. Never commits: review with `git diff`, undo with `git restore`.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
agents=$root/AGENTS.md

usage() {
  echo "Usage: $0 [-n|--dry-run] [-y|--yes] <skill>" >&2
  exit 1
}

dry_run=0
yes=0
skill=
while [ $# -gt 0 ]; do
  case $1 in
    -n | --dry-run) dry_run=1 ;;
    -y | --yes) yes=1 ;;
    -*) usage ;;
    *) [ -z "$skill" ] || usage; skill=$1 ;;
  esac
  shift
done
[ -n "$skill" ] || usage

if ! [[ $skill =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid skill name '$skill' (use lowercase letters, digits and dashes)" >&2
  exit 1
fi

# Skill directories named <skill> that contain a SKILL.md (this excludes category folders)
matches=()
for candidate in "$root/skills/$skill" "$root"/skills/*/"$skill"; do
  [ -f "$candidate/SKILL.md" ] && matches+=("$candidate")
done
if [ ${#matches[@]} -gt 1 ]; then
  echo "Error: skill '$skill' exists in several places, remove the extra copies by hand:" >&2
  printf '  %s\n' "${matches[@]#"$root"/}" >&2
  exit 1
fi
dir=${matches[0]:-}

# Row in the vendored table of AGENTS.md (only above the end marker)
row=$(awk -v prefix="| \`$skill\` |" '
  /<!-- vendored:end -->/ { exit }
  index($0, prefix) == 1 { print; exit }
' "$agents")

if [ -z "$dir" ] && [ -z "$row" ]; then
  echo "Error: skill '$skill' not found in skills/ or in AGENTS.md" >&2
  exit 1
fi

# Checked before any change so the directory and the table never get out of sync
if [ -n "$row" ] && ! grep -q '<!-- vendored:end -->' "$agents"; then
  echo "Error: <!-- vendored:end --> marker missing in AGENTS.md, cannot remove the row of $skill" >&2
  exit 1
fi

echo "Removing skill '$skill':"
if [ -n "$dir" ]; then
  echo "  directory: ${dir#"$root"/}"
else
  echo "  directory: none (already deleted)"
fi
if [ -n "$row" ]; then
  echo "  AGENTS.md row: $row"
else
  echo "  AGENTS.md row: none (personal skill)"
fi

# Other skills mentioning this one would be left with a dangling reference
if [ -n "$dir" ]; then
  refs=$(grep -rlw --include=SKILL.md -- "$skill" "$root/skills" 2>/dev/null | grep -v "^$dir/" || true)
  if [ -n "$refs" ]; then
    echo "Warning: other skills mention '$skill':" >&2
    echo "$refs" | sed "s|^$root/|  |" >&2
  fi
fi

if [ $dry_run -eq 1 ]; then
  echo "Dry run, nothing removed"
  exit 0
fi

if [ $yes -eq 0 ]; then
  [ -t 0 ] || { echo "Error: not a terminal, pass --yes to confirm the removal" >&2; exit 1; }
  read -r -p "Proceed? [y/N] " answer
  case $answer in
    y | Y | yes | YES) ;;
    *) echo "Aborted"; exit 1 ;;
  esac
fi

if [ -n "$dir" ]; then
  rm -rf "$dir"
  parent=$(dirname "$dir")
  # Drop the category folder if that was its last skill
  [ "$parent" != "$root/skills" ] && rmdir "$parent" 2>/dev/null || true
fi

if [ -n "$row" ]; then
  awk -v prefix="| \`$skill\` |" '
    /<!-- vendored:end -->/ { done = 1 }
    !done && index($0, prefix) == 1 { next }
    { print }
  ' "$agents" > "$agents.tmp"
  mv "$agents.tmp" "$agents"
fi

echo "Removed $skill. Review with git diff, then commit."
