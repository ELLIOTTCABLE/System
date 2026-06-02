#!/usr/bin/env bash
# Create this turn's append-only notes file. The turn-number comes from the files already
# on disk and the date from the real clock, so neither can be mis-stamped by hand.
# Usage:  new-turn.sh <research-dir>   (prints the new file's path)
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: new-turn.sh <research-dir>" >&2; exit 1; }
dir=$1
mkdir -p "$dir"
shopt -s nullglob
existing=( "$dir"/turn*-notes.md )
n=$(( ${#existing[@]} + 1 ))
f="$dir/turn$(printf %02d "$n")-$(date +%F)-notes.md"
printf '# turn %d — %s\n\n' "$n" "$(date '+%F %T %Z')" > "$f"
echo "$f"
