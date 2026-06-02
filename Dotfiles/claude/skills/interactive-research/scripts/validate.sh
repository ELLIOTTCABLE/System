#!/usr/bin/env bash
# Final gate before a turn's artifacts reach the human. The bracketed reference-format —
# [B-moeller-spa-2025] — is the required way to cite. Artifacts are scanned newest-first
# (by mtime), so issues in what you just edited surface at the top:
#
#   ERROR (exit 1): a BRACKETED CANONICAL slug ([A-F]-<lower-kebab>-<4-digit-year>) that is
#     not a key in sources.json — a typo, a wrong grade-letter, or a source never registered.
#   warn  (exit 0, your call): everything else slug-shaped —
#     - a bracketed but OFF-CANONICAL token (lower-case grade, missing year), since models
#       slug loosely; and
#     - a fully-formed UNBRACKETED slug ([A-F]-…-<4 digits>): usually a real-or-hallucinated
#       source written in citation form but missing its brackets — the case worth catching.
#     Warnings are capped (see WARN_CAP); weaker unbracketed forms are deliberately ignored.
#
# sources.json is clean-by-construction (new-source.sh) and is not re-checked.
#
# Usage:  validate.sh <research-dir>
# Exit:   0 clean or warnings-only · 1 unregistered canonical citation(s) · 2 usage/tooling error
set -euo pipefail
WARN_CAP=20

die() { printf 'validate: %s\n' "$*" >&2; exit 2; }

[ $# -eq 1 ] || die "usage: validate.sh <research-dir>"
dir=$1
command -v jq >/dev/null || die "jq not found"
[ -d "$dir" ] || die "no such dir: $dir"

src="$dir/sources.json"
keys=$([ -f "$src" ] && jq -r 'keys[]' "$src" || true)

# Artifacts newest-first; the literal glob (no match) yields no lines, so arts stays empty.
arts=()
while IFS= read -r f; do arts+=("$f"); done < <(ls -t "$dir"/*.md 2>/dev/null)
[ ${#arts[@]} -gt 0 ] || { echo "validate: no .md artifacts in $dir — nothing to check"; exit 0; }

cite_re='\[[A-Fa-f]-[A-Za-z0-9._-]+\]'             # bracketed citation, either grade case
canon_re='^[A-F]-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{4}$' # strict canonical slug
strong_re='[A-F]-[A-Za-z0-9_-]+-[0-9]{4}'          # fully-formed slug, bracket-agnostic

errors=() warns=()
for f in "${arts[@]}"; do
   while IFS= read -r ln; do
      [ -n "$ln" ] || continue
      tok=${ln#*:}; slug=${tok#[}; slug=${slug%]}; line=${ln%%:*}
      if [[ $slug =~ $canon_re ]]; then
         if grep -Fxq -- "$slug" <<<"$keys"; then continue; fi
         errors+=("$(printf 'ERROR  unregistered   %-34s  %s:%s' "$slug" "$f" "$line")")
      else
         if   [[ $slug =~ ^[a-f]- ]];      then why="lower-case grade"
         elif [[ ! $slug =~ -[0-9]{4}$ ]]; then why="missing year"
         else                                   why="off-canonical"; fi
         warns+=("$(printf 'warn   %-16s  %-34s  %s:%s' "$why" "$slug" "$f" "$line")")
      fi
   done < <(grep -oEn "$cite_re" "$f" || true)

   # Unbracketed strong slugs: strip bracketed spans first (sed keeps line count), then match.
   while IFS= read -r ln; do
      [ -n "$ln" ] || continue
      slug=${ln#*:}; line=${ln%%:*}
      warns+=("$(printf 'warn   %-16s  %-34s  %s:%s' "unbracketed" "$slug" "$f" "$line")")
   done < <(sed 's/\[[^][]*\]//g' "$f" | grep -oEn "$strong_re" || true)
done

errc=${#errors[@]} warnc=${#warns[@]}
[ "$errc" -eq 0 ] || for e in "${errors[@]}"; do printf '  %s\n' "$e" >&2; done
if [ "$warnc" -gt 0 ]; then
   shown=0
   for w in "${warns[@]}"; do
      [ "$shown" -lt "$WARN_CAP" ] || break
      printf '  %s\n' "$w" >&2; shown=$((shown + 1))
   done
   [ "$warnc" -le "$WARN_CAP" ] \
      || printf 'validate: %d warnings; showing the %d in the most-recently-changed files (%d more suppressed).\n' "$warnc" "$WARN_CAP" "$((warnc - WARN_CAP))" >&2
fi

if [ "$errc" -ne 0 ]; then
   printf 'validate: %d unregistered citation(s) — register with new-source.sh, fix the slug, or drop the reference.\n' "$errc" >&2
   exit 1
fi
if [ "$warnc" -ne 0 ]; then
   printf 'validate: no errors; %d warning(s) above are yours to adjudicate.\n' "$warnc" >&2
else
   echo "validate: OK — every canonical citation resolves to $src"
fi
