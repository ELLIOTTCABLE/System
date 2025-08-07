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
