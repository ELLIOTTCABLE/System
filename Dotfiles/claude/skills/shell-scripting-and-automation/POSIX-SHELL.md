# sh
- I almost always want POSIX-compliant sh code, unless I specifically indicate otherwise. The only exception is files that explicitly list a non-sh, non-bash shell in their shebang line (eg. `#!/usr/bin/env zsh`)
- I prefer using the most complicated and powerful shell-scripting available for the task: in POSIX scripts, be sure to use parameter expansion, word-splitting, and the like, to avoid unnecessary external programs. As some examples, where reasonable and more terse, use:
  - shell-arithmetic `$(( ))` (instead of `expr`)
  - parameter-expansion (instead of `cut`, `awk`, `sed`)
  - shell pattern-matching - `case`, `[[ string == pattern* ]]`, etc (instead of `grep`)
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
FILLME
