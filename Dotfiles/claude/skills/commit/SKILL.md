---
name: commit
description: The user's idiosyncratic commit-message style — `(label1 label2) terse message` with the mandatory `AI` tag for AI-authored commits, using the `.gitlabels` convention. Two-mode operation — autonomous-commit on `ai/*` branches (or with a `.claude-commit` sentinel), message-only on others. Read whenever drafting a commit message, staging a commit, or finishing a chunk of work that will produce a commit.
when_to_use: Load when the user asks to "commit", "make a commit", "stage and commit", "wrap this up", or otherwise signals a commit is imminent; or when deciding to make commits during an autonomous chunk of work.
---

# Commit message authoring

The user follows the [`.gitlabels`](https://github.com/ELLIOTTCABLE/.gitlabels) convention: every commit message starts with parenthesised tags describing the commit's nature and importance.

Labels exist for *filtering* - they are a way to quickly review and find history; for instance, "I need to find changes to this folder but ignore all the small noisy changes" (grep excluding `-`); "I need to review the behaviour changes" (grep excluding `meta|doc|noop`), and so-on.

## Two modes

The user runs in one of two 'modes'; check which is active *before* deciding whether to execute a commit.

**Mode is determined by:**
1. Run `git branch --show-current` to get the active branch.
2. Check for a `.claude-commit` sentinel file at the repo root (`git rev-parse --show-toplevel`).

**Autonomous mode** — the current branch matches `ai/*`, *or* a `.claude-commit` sentinel exists at the repo root. The user is using this branch as a working space and will review/rebase your commits later. → After authoring the message, **you may run `git commit` yourself.**

**Restricted mode (default)** — anything else. → Produce the commit message and the exact `git commit -m '...'` invocation; **do not execute it.** Present it to the user to run.

The user's hook system enforces this deterministically: it will block `git commit` from any tool call when not in autonomous mode. So this isn't a guess — running a commit on a non-allowed branch will hard-fail. These skill instructions and the hook should always agree.

## Hard constraints (both modes)
- **`git push` is always forbidden, regardless of mode.** Remote state is the user's. Even on `ai/*` branches, do not push.
- **No other mutative git** unless explicitly directed by the user. The hook also blocks `git rebase`, `git merge`, `git reset --hard`, `git clean -f`, `git branch -d`/`-D`/`--delete`, `git stash drop`/`clear`, `git tag -d`/`--delete`, `git filter-branch`/`filter-repo`, and `git update-ref`. Read-only inspection (`git status`, `git diff`, `git diff --staged`, `git log`, `git show`, `git branch --show-current`) is always fine and encouraged before authoring a message.
- **Every commit you author must include the `AI` label.** No exceptions. The user uses this label to identify AI-authored commits during review-and-rebase.
- **Skip the `Co-Authored-By: Claude...` trailer.** The `(AI)` label is the canonical attribution; the trailer would duplicate it.
- **Write single-line commit messages.** Context is lost in multiline formats for most readers; and rarely is a task complex enough to justify them.
- **For substantive code edits, run the `review-pass` skill after all work/commits are complete.** That skill cleans up overly-verbose AI-added comments before they get committed. Trivial commits (config tweaks, single-line fixes, doc-only) don't need it.

## Preferred command forms

When you do need a git mutation, use the modern delineated commands rather than the overloaded older ones:

- **branch ops** — `git switch <branch>` / `git switch -c <branch>`, *not* `git checkout` / `git checkout -b` (which overloads branch-switching with file-discarding)
- **unstaging** — `git restore --staged <file>`, *not* `git reset HEAD <file>`
- **never** use bare `git restore <file>` or `git checkout -- <file>` — both discard working-tree changes; that's the user's call, not yours

`git switch` refuses to clobber uncommitted changes by default, which matches the user's safety preferences. The old `git checkout` made branch-switching and file-discarding share a verb; avoid the ambiguity entirely.

## Format

```
(lbl1 lbl2 ...) Do thing to code
```

Labels in parens at the very first byte. Space-separated, one line, no trailing period, no body unless absolutely necessary — if you reach for one, the change probably wants to be split into multiple commits.

Labels should be sourced from `.gitlabels` in the repo, if present; or `git log --oneline` history for the relevant files if absent. Introducing new labels should be an active, conscious decision, and is fairly rare. Labels should not duplicate folder/component names; they're for metadata and cross-cutting concerns that affect multiple modules and trees.

## Importance markers

- *no importance marker* — normal commit. **This is the default for AI commits.**
- `(-)` — minor / unimportant (typo, README touchup, single small ignore-add). Combined with substantive labels: `(- doc fix)`, `(- meta new)`.
- `(!!)` — major / widespread / "landing a huge refactor". Rare.

You will almost never produce a `(-)` commit (those are usually tiny tweaks the user usually does manually; AIs tend to land all work at once) or a `(!!)` commit (those are sweeping landings that can't be safely broken into standalone work-units; the user drives these).

## The mandatory `AI` label

Every AI commit gets `AI` somewhere in the label group. Position is flexible — match the rhythm of the others:

```
(AI new) Add lockfile-merge driver
(re AI conf) Reorder mise plugins
(- AI doc) Fix outdated link
```

## Core labels

Most commits use one or two of these. **At least one of `new`, `fix`, or `re` should apply** to every substantive commit; pure-doc/meta/style/tests commits use those instead.

| label | meaning |
| --- | --- |
| `new` | new functionality, file, or content |
| `fix` | fixes a bug or problem |
| `re` | refactor; subtle improvement, no behavioural change visible to consumers |
| `doc` | only commentary/README/docs (no executable code) |
| `meta` | meta-project (CI, package.json housekeeping, gitignore) |
| `style` | only whitespace/alignment/formatting |
| `tests` | only test-suite changes |
| `dep` | dependency add/remove/swap |
| `dep up` | bumping a dependency's version |
| `rm` | removal of 'something' that isn't just code deletions (often paired: `(rm dep)`, `(rm tool)`) |
| `pkg` / `tool` / `conf` | packaging / tooling / configuration |
| `typ` | typing / type-system |
| `sec` | security |
| `API` / `BRK` | public-API-surface / breaking change (almost always paired with `(!!)`) |
| `typo` | typo (almost always paired with `-`) |

For project-specific labels (e.g. `nsib`, `VSC`, `MLm`, `Mac`, `Win`, `FF ext`, `dsgn`, `prsr`, `lex`, `JSintf`, `reactor`): **read the project's `.gitlabels` file** before committing in any project that has one. Use existing project labels rather than inventing new ones. If no `.gitlabels` exists, best to stick to the core labels above or ones you can find in the git-history that are clearly relevant to your work.

Aim for 2-3 labels inc `(AI)`, 4 at most.

## Voice

Brief, scannable, often telegraphic. Imperative ("Add", "Repair") where possible. Personality is fine. Aim for under ~60 characters of message text after the labels; long messages are a smell.

## Anti-patterns

- **Restating the diff.** If the only files changed are under `Compiler/`, the message must not say "Fix the compiler" — the file list already conveys that. Use the description to say *what specifically* changed, e.g. `(fix lex) Recover from unterminated string`.
- **Restating the label.** `(new) Add new flag --verbose` repeats `new`. Drop the redundancy: `(new) --verbose flag for diagnostics`.
- **Ceremony words.** "This commit", "introduces", "adds support for". Drop them.
- **Prose bodies.** Almost never warranted.

## Procedure

1. Read what's about to commit: `git status`, `git diff --staged` (or `git diff` if not yet staged).
2. **Determine the mode.** Run `git branch --show-current` and check whether `.claude-commit` exists at the repo root. Either condition (matching branch pattern or sentinel file present) puts you in autonomous mode; otherwise restricted.
3. If a `.gitlabels` exists in the repo root, read it for project-specific labels.
4. Pick labels: at least one of `new`/`fix`/`re` (or `doc`/`meta`/`style`/`tests` for those categories), plus any qualifiers, plus `AI`.
5. Write a brief description that complements — does not duplicate — the file list.
6. **Act per mode:**
    - **Autonomous:** stage if needed, run `git commit -m '...'` yourself, and report the resulting commit hash to the user.
    - **Restricted:** present the message and the exact `git commit -m '...'` invocation for the user to execute. Do not run it.
7. If this is the last change and completes the user's requested work, and the changes include substantive AI-authored code edits, invoke the `review-pass` skill before declaring the task done.
8. If the `review-pass` skill ran, include its kept-comments report in the same writeup (see that skill's reporting section).
