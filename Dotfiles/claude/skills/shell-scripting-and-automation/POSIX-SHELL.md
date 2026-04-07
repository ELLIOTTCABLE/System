# sh
- I almost always want POSIX-compliant sh code, unless I specifically indicate otherwise. The only exception is files that explicitly list a non-sh, non-bash shell in their shebang line (eg. `#!/usr/bin/env zsh`)
- I prefer using the most complicated and powerful shell-scripting available for the task: in POSIX scripts, be sure to use parameter expansion, word-splitting, and the like, to avoid unnecessary external programs. As some examples, where reasonable and more terse, use:
  - shell-arithmetic `$(( ))` (instead of `expr`)
  - parameter-expansion (instead of `cut`, `awk`, `sed`)
  - shell pattern-matching - `case` (POSIX), `[[ string == pattern* ]]` (zsh/bash), etc (instead of `grep`)
  - command-substitution and the array (instead of `xargs`)
- Additionally, where zsh features are available (i.e. in files with a zsh shebang or `zsh` in the name), prefer advanced zsh features wherever possible. Read the `zshall` manpage; and reference resources like <https://cmngoal.com/zsh-cheatsheet>. Ex.:
  - zsh arrays and array-slicing
  - zsh globbing (including `**`, `^`, and the like)
  - zsh powerful parameter-expansion (including `${(j: :)array}` and the like)
- I use an unusual style for my shell-script; so be extra-careful to match surrounding code-style. In *my* scripts (but not *all* scripts you'll see), this will include:
  - unusual indentation
  - Ruby-esque if/else-on-two-lines with `; fi` at the end of lines instead of on the next line
  - extra/additional whitespace inline to vertically and visually align things like case-statements

## Examples

### In all POSIX sh
```sh
# Parameter expansion over external programs (`basename`, `sed`, `cut`):
[ -z "${0%%*.sh}" ] && sh_file=yes
fname="${arg##*/}"; fname="${fname%.log}"

# Negation/default via parameter expansion (not `grep` or `test`):
[ -n "${ALL_USERS##[NFnf]*}" ] && all_users=yes

# `case` for pattern-matching (not `grep`):
case $yn in
   [Yy]*) ;;
       *) exit 1;;
esac

# Terse one-liner helpers:
puts() { printf %s\\n "$@" ;}
move-n-link()( [ $# -ne 2 ] && print "Usage: move-n-link FROM TO" && exit 1;
   mv "$1" "$2" && { ln -s "$2" "$1" || mv "$2" "$1" ;} )

# Ruby-esque `; fi` on same line, not next line:
if [ "$(uname -s)" != "Darwin" ]; then
   puts '!! FATAL: `jxa-async` can only be meaningfully installed on macOS.'
   exit $err_wrong_platform                                                   ;fi

# Vertical alignment of `;;` and values:
case "${answer:-$2}" in
   [Yy]*) return 0                                                   ;;
   [Nn]*) return 1                                                   ;;
   *)     printf %s "Please enter 'YES' or 'NO': "                   ;;
esac

# Vertical alignment for related assignments/dumps:
[ -n "$DEBUG_SCRIPTS" ] && puts \
   "\$0:                   '${0}'"                                            \
   "Terminal input:        ${term_in:--no}"                                   \
   "Effective user-name:  '${effective_user_name}'"                           \
   "" >&2
```

### Only relevant in zsh
```zsh
# zsh dynamic named directories + parameter expansion:
uncommitish() { if [[ $1 == 'n' ]]; then
   if [[ -z "$UNCOMMITISH_REPO" ]]; then return 1; fi
   rev=$(git --git-dir="$UNCOMMITISH_REPO/.git" rev-parse --verify "$2" 2>/dev/null); st=$?
   if (( st != 0 )); then return $st; fi
   reply=("$rev")
else return 1; fi ;}

# zsh array manipulation:
zsh_directory_name_functions=(${zsh_directory_name_functions[@]} uncommitish set_uncommitish_repo)

# Inline one-liner functions w/ `;}`:
van()  {  vim               '+call vimman#("'"$1"'")' ;}
nrs(){ local script="$1"; shift; npm --loglevel=silent run-script "$script" -- "$@" ;}
```
