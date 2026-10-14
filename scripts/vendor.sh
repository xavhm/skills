#!/usr/bin/env bash
# Vendor third-party skills into skills/ and record their sources in AGENTS.md.
#
# Usage:
#   scripts/vendor.sh                                          update every skill listed in AGENTS.md
#   scripts/vendor.sh <owner/repo | git-url> <skill> [category]   add or update a single skill
#
# With a category, the skill goes to skills/<category>/<skill>/, otherwise skills/<skill>/.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
agents=$root/AGENTS.md

# No arguments: re-vendor every row of the AGENTS.md table
if [ $# -eq 0 ]; then
  rows=$(awk '/<!-- vendored:end -->/ { exit } /^\| `/ { print }' "$agents")
  [ -n "$rows" ] || { echo "Error: no vendored skills listed in AGENTS.md, nothing to update" >&2; exit 1; }

  failed=()
  while IFS='|' read -r _ skill category repo _; do
    skill=$(echo "$skill" | tr -d '` ')
    category=$(echo "$category" | tr -d ' ')
    repo=$(echo "$repo" | tr -d ' ')
    [ "$category" = "-" ] && category=""
    "$0" "$repo" "$skill" "$category" || failed+=("$skill")
  done <<< "$rows"

  if [ ${#failed[@]} -gt 0 ]; then
    echo "Error: failed to vendor: ${failed[*]}" >&2
    exit 1
  fi
  exit 0
fi

{ [ $# -eq 2 ] || [ $# -eq 3 ]; } || {
  echo "Usage: $0 [<owner/repo | git-url> <skill> [category]]" >&2
  exit 1
}
repo=$1
skill=$2
category=${3:-}

if [ -n "$category" ] && ! [[ $category =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid category '$category' (use lowercase letters, digits and dashes)" >&2
  exit 1
fi

case $repo in
  *://* | git@*) url=$repo ;;
  *) url=https://github.com/$repo.git ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git clone --quiet --depth 1 "$url" "$tmp/src" || {
  echo "Error: could not clone $repo ($url)" >&2
  exit 1
}
sha=$(git -C "$tmp/src" rev-parse --short HEAD)

# Shallowest directory named <skill> that contains a SKILL.md
src=$(
  find "$tmp/src" -name .git -prune -o -type f -name SKILL.md -print |
    while read -r f; do
      d=$(dirname "$f")
      [ "$(basename "$d")" = "$skill" ] && echo "$d"
    done |
    awk '{ print gsub("/", "/"), $0 }' | sort -n | head -1 | cut -d' ' -f2-
) || src=
# Fallback: the repo itself is the skill
if [ -z "$src" ] && [ -f "$tmp/src/SKILL.md" ]; then
  src=$tmp/src
fi
[ -n "$src" ] || { echo "Error: skill '$skill' not found in $repo (no directory named '$skill' containing a SKILL.md)" >&2; exit 1; }

rel=${src#"$tmp/src"}
rel=${rel#/}
rel=${rel:-.}

dest=$root/skills/${category:+$category/}$skill

# Remove a previous copy of this skill at another location (e.g. category changed)
for old in "$root/skills/$skill" "$root"/skills/*/"$skill"; do
  if [ "$old" != "$dest" ] && [ -f "$old/SKILL.md" ]; then
    rm -rf "$old"
    parent=$(dirname "$old")
    [ "$parent" != "$root/skills" ] && rmdir "$parent" 2>/dev/null || true
  fi
done

mkdir -p "$(dirname "$dest")"
rm -rf "$dest"
cp -R "$src" "$dest"
rm -rf "$dest/.git"

grep -q '<!-- vendored:end -->' "$agents" || {
  echo "Error: <!-- vendored:end --> marker missing in AGENTS.md, cannot record $skill" >&2
  exit 1
}

# Upsert the skill's row in the vendored table of AGENTS.md
row="| \`$skill\` | ${category:--} | $repo | \`$rel\` | \`$sha\` | $(date +%F) |"
awk -v prefix="| \`$skill\` |" -v row="$row" '
  index($0, prefix) == 1 { next }
  /<!-- vendored:end -->/ { print row }
  { print }
' "$agents" > "$agents.tmp"
mv "$agents.tmp" "$agents"

echo "Vendored $skill from $repo@$sha into ${dest#"$root"/}"
