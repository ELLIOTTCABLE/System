#!/usr/bin/env sh
# Register one graded source: validate the model-authored fields, archive the artifact,
# stamp the mechanical fields, and append the entry to <research-dir>/sources.json.
#
# Usage:  new-source.sh <research-dir> <slug>   < entry.json
#   <research-dir>  the topic's dir, e.g. .claude/research/<topic>
#   <slug>          <A-F grade>-<lower-kebab-name>-<YYYY>, e.g. B-moeller-spa-2025
#   stdin           a JSON object with exactly the model-authored fields:
#                     url, grading-certainty, grading-reasoning, relevance-certainty,
#                     relevance-description, graded-by, published, via
#
# Generates `retrieved` (today) and `sha256` (of the archived copy), then writes the
# completed entry into sources.json and echoes it to stdout. Refuses to overwrite an
# existing slug — the manifest is append-only.
set -eu

die() { printf 'new-source: %s\n' "$*" >&2; exit 1; }
matches() { printf '%s\n' "$1" | grep -Eq -- "$2"; }

[ $# -eq 2 ] || die "usage: new-source.sh <research-dir> <slug>  < entry.json"
dir=$1; slug=$2
command -v jq   >/dev/null 2>&1 || die "jq not found — install it (brew install jq / mise use -g jq)"
command -v curl >/dev/null 2>&1 || die "curl not found"

matches "$slug" '^[A-F]-[a-z0-9]+(-[a-z0-9]+)*-(19|20)[0-9]{2}$' \
   || die "slug '$slug' must be <A-F>-<lower-kebab>-<YYYY>, e.g. B-moeller-spa-2025"

entry=$(cat)
[ -n "$entry" ] || die "no JSON on stdin"
printf '%s' "$entry" | jq -e . >/dev/null 2>&1 || die "stdin is not valid JSON"

field() { printf '%s' "$entry" | jq -r --arg k "$1" '.[$k] // empty'; }
for k in url grading-certainty grading-reasoning relevance-certainty relevance-description graded-by published via; do
   [ -n "$(field "$k")" ] || die "missing or empty field: $k"
done

matches "$(field url)" '^https?://' || die "url must be http(s)://…"
for k in grading-certainty relevance-certainty; do
   matches "$(field "$k")" '^([+]1:SURE|-0:SUSPECT|-1:GUESS|-2:WONDER)$' \
      || die "$k must be one of +1:SURE / -0:SUSPECT / -1:GUESS / -2:WONDER"
done
matches "$(field graded-by)" '^(subagent|top-level-agent|human)$' \
   || die "graded-by must be subagent / top-level-agent / human"
matches "$(field published)" '^[0-9]{4}(-[0-9]{2}){0,2}$' \
   || die "published must be YYYY, YYYY-MM, or YYYY-MM-DD"

src="$dir/sources.json"
mkdir -p "$dir/sources"
[ -f "$src" ] || echo '{}' > "$src"
[ "$(jq -r --arg s "$slug" 'has($s)' "$src")" = false ] || die "slug '$slug' already registered (append-only)"

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
curl -fsSL --retry 2 "$(field url)" > "$tmp" || die "download failed: $(field url)"
[ -s "$tmp" ] || die "downloaded nothing from $(field url)"
case "$(head -c 4 "$tmp")" in
   %PDF) ext=pdf ;;
   *) case "$(field url)" in
         *.pdf) ext=pdf ;; *.htm|*.html) ext=html ;; *.txt) ext=txt ;;
         *.md) ext=md ;; *.json) ext=json ;; *) ext=html ;;
      esac ;;
esac
artifact="$dir/sources/$slug.$ext"
mv "$tmp" "$artifact"; trap - EXIT

if   command -v sha256sum >/dev/null 2>&1; then sha=$(sha256sum "$artifact" | cut -d' ' -f1)
elif command -v shasum    >/dev/null 2>&1; then sha=$(shasum -a 256 "$artifact" | cut -d' ' -f1)
else die "need sha256sum or shasum"; fi

full=$(printf '%s' "$entry" | jq --arg r "$(date +%F)" --arg sha "$sha" '{
   url:                     .url,
   "grading-certainty":     .["grading-certainty"],
   "grading-reasoning":     .["grading-reasoning"],
   "relevance-certainty":   .["relevance-certainty"],
   "relevance-description": .["relevance-description"],
   "graded-by":             .["graded-by"],
   published:               .published,
   retrieved:               $r,
   sha256:                  $sha,
   via:                     .via
}')

out="$src.tmp"
jq --arg s "$slug" --argjson e "$full" '.[$s] = $e' "$src" > "$out" && mv "$out" "$src"

jq -n --arg s "$slug" --argjson e "$full" '{($s): $e}'
printf 'new-source: archived %s\n' "$artifact" >&2
