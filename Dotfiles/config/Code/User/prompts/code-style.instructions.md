---
applyTo: '**'
---
- I don't like redundant comments. Comments should explain "why", not what or how; the code should be self-explanatory.
- In cases where you might be tempted to use a comment, consider whether using an intermediate clearly-named variable will explain the same thing (but avoid overusing this; a simple readable inline chain is just fine).
- Please make sure you run the existing tests every single time you change anything.
- When writing tests, I prefer very little genericness, nor does the code need to be D.R.Y. It's perfectly acceptable to repeat things in the context of unit tests; they should stand fairly alone.
- If a change you make is easily testable, add tests for the change; but avoid noisy, pointless tests - make sure to reason through the behaviour you're considering testing, and come to a reasoned argument as to why adding that particular test adds actual value. (Tell me if you considered testing and opted not to, and include information about *why* you chose not to.)

My priorities for code are almost always, in order:
1. Maintainability (in particular, readability - how well it scans, to an experiemced developer)
2. Simplicity (less code is better, but not at the cost of readability)
3. Correctness (entry-point validation, script type-handling and newtypes, and the like)
4. and only then, performance (unless I indicate otherwise.)

Generally speaking, asking me about my priorities with respect to a particular piece of code is a good idea. If you see cases where 1, 2, 3, or 4 are in conflict, please detail those cases to me.

I use three spaces for indentation wherever possible - not 2, and not 4. Try and stick to that, unless there's substantial content already in the file that's using 2 or 4 spaces.

# Environment-specific preferences

The following preferences are specific to individual languages, although they may give you a feel for my general preferences as well:

### Shell scripts, bash, zsh, etc.

-  I almost always want POSIX-compliant sh code, unless I specifically indicate otherwise. The only exception is files that explicitly list a non-sh, non-bash shell in their shebang line (eg. `#!/usr/bin/env zsh`)
-  I prefer using the most complicated and powerful shell-scripting available for the task: in POSIX scripts, be sure to use parameter expansion, word-splitting, and the like, to avoid unnecessary external programs. As some examples, where reasonable and more terse, avoid:
   -  `expr` in favour of shell-arithmetic (`$(( ))`);
   -  `cut`, `awk`, and `sed` in favour of shell parameter-expansion;
   -  `grep` in favour of shell pattern-matching (`case`, `[[ string == pattern* ]]`, etc);
   -  `xargs` in favour of command-substitution and arrays.
-  Similarly, where zsh features are present, or a zsh shebang, prefer advanced zsh features wherever possible. Read the `zshall` manpage; and reference resources like <https://cmngoal.com/zsh-cheatsheet>. Some examples include:
   -  zsh arrays and array-slicing;
   -  zsh globbing (including `**`, `^`, and the like);
   -  zsh powerful parameter-expansion (including `${(j: :)array}` and the like);
-  I use an unusual style for my shell-script; please attempt to match the surrounding code-style, including:
   -  unusual indentation;
   -  Ruby-esque if/else-on-two-lines with `; fi` at the end of lines instead of on the next line;
   -  extra/additional whitespace inline to vertically and visually align things like case-statements

Shell-script is one of the few exceptions to my priorities above, in particular simplicity: I prefer terse shell-scripts that rely heavily on builtin shell-features and deep knowledge of shell behaviour, even if that makes them harder to read for a casual reader. If you don't understand something in a shell-script, please ask me about it; and feel free to generate 'clever' code (ensuring that you explain to me in detail what's going on in your changes if they're non-obvious, so I don't miss them; including word-splitting, parameter expansion, and the like.)
