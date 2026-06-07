#!/usr/bin/env sh
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
#       (Exempt: a slug written as its on-disk path, sources/<slug>.<ext>, when registered —
#       a filename, not a citation; an unregistered sources/ path still warns.)
#     Warnings are capped (see WARN_CAP); weaker unbracketed forms are deliberately ignored.
#
# sources.json is clean-by-construction (new-source.sh) and is not re-checked.
#
# Usage:  validate.sh <research-dir>
# Exit:   0 clean or warnings-only · 1 unregistered canonical citation(s) · 2 usage/tooling error
set -eu
WARN_CAP=20

die() { printf 'validate: %s\n' "$*" >&2; exit 2; }
matches() { printf '%s\n' "$1" | grep -Eq -- "$2"; }

if ! command -v jq >/dev/null 2>&1 && command -v mise >/dev/null 2>&1 && [ -z "${_IR_VIA_MISE:-}" ]; then
   exec env _IR_VIA_MISE=1 mise exec -- sh "$0" "$@"
fi

[ $# -eq 1 ] || die "usage: validate.sh <research-dir>"
dir=$1
printf 'validate: cwd %s — checking %s\n' "$(pwd)" "$dir" >&2
command -v jq >/dev/null 2>&1 || die "jq not found"
[ -d "$dir" ] || die "no such dir: $dir"

src="$dir/sources.json"
if [ -f "$src" ]; then keys=$(jq -r 'keys[]' "$src"); else keys=; fi
is_key() { printf '%s\n' "$keys" | grep -Fxq -- "$1"; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
errf="$work/err"; warnf="$work/warn"; : > "$errf"; : > "$warnf"

cite_re='\[[A-Fa-f]-[A-Za-z0-9._-]+\]'             # bracketed citation, either grade case
# Strict canonical slug. The year is matched as any 4 digits here — deliberately laxer than
# new-source.sh's (19|20)YY. That asymmetry is load-bearing: a canonical-shaped but
# unregisterable cite like [A-xyz-2250] must resolve to nothing and ERROR, not slip to a
# warn. Do not "unify" this with new-source.sh's slug_re without re-reading that contract.
canon_re='^[A-F]-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{4}$'
strong_re='\b[A-F]-[A-Za-z0-9_-]+-[0-9]{4}\b'      # fully-formed slug, bracket-agnostic; \b skips CVE-YYYY-NNNNN false-matches (GNU/BSD ext)

# Every *.md under the tree (tiered research-dirs included), newest-first — but never the
# sources/ archive, whose files are copies of external sources, not our own artifacts.
find "$dir" -type d -name sources -prune -o -type f -name '*.md' -print0 2>/dev/null > "$work/found"
[ -s "$work/found" ] || { echo "validate: no .md artifacts under $dir — nothing to check"; exit 0; }
xargs -0 ls -t < "$work/found" > "$work/arts" 2>/dev/null || true

while IFS= read -r f; do
   [ -n "$f" ] || continue
   grep -oEn "$cite_re" "$f" 2>/dev/null | while IFS= read -r ln; do
      [ -n "$ln" ] || continue
      tok=${ln#*:}; slug=${tok#[}; slug=${slug%]}; line=${ln%%:*}
      if matches "$slug" "$canon_re"; then
         if is_key "$slug"; then continue; fi
         printf 'ERROR  unregistered   %-34s  %s:%s\n' "$slug" "$f" "$line" >> "$errf"
      else
         case "$slug" in
            [a-f]-*) why="lower-case grade" ;;
            *) if matches "$slug" '-[0-9]{4}$'; then why="off-canonical"; else why="missing year"; fi ;;
         esac
         printf 'warn   %-16s  %-34s  %s:%s\n' "$why" "$slug" "$f" "$line" >> "$warnf"
      fi
   done
   # Unbracketed strong slugs: strip bracketed spans first (sed keeps line count), then match.
   # Carve-out: a slug written as its on-disk archive path (sources/<slug>.<ext>, where
   # new-source.sh puts every copy) is a file reference to a registered source, not a forgotten
   # citation — exempt it when the slug is a key. Match an optional sources/ prefix so the path
   # form is distinguishable from a bare slug; a sources/ path to an *un*registered slug still warns.
   sed 's/\[[^][]*\]//g' "$f" | grep -oEn "(sources/)?$strong_re" 2>/dev/null | while IFS= read -r ln; do
      [ -n "$ln" ] || continue
      tok=${ln#*:}; line=${ln%%:*}
      case "$tok" in
         sources/*) slug=${tok#sources/}; is_key "$slug" && continue ;;
         *) slug=$tok ;;
      esac
      printf 'warn   %-16s  %-34s  %s:%s\n' "unbracketed" "$slug" "$f" "$line" >> "$warnf"
   done
done < "$work/arts"

errc=$(wc -l < "$errf" | tr -d ' ')
warnc=$(wc -l < "$warnf" | tr -d ' ')

[ "$errc" -eq 0 ] || sed 's/^/  /' "$errf" >&2
if [ "$warnc" -gt 0 ]; then
   sed 's/^/  /' "$warnf" | head -n "$WARN_CAP" >&2
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
