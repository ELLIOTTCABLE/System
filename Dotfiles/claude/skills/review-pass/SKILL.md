---
name: review-pass
description: End-of-work hygiene pass for AI-edited code, focused on stripping the overly-verbose code comments that AIs habitually generate. The user wants ~90% of AI-added comments deleted, the remaining ~10% rewritten for brutal brevity. Read this before declaring an autonomous task complete, before drafting a commit on substantive edits, or whenever the user asks for a "review pass", "cleanup", or "wrap-up".
when_to_use: Load when finishing autonomous work that produced code edits; before invoking the `commit` skill on substantive changes; or when the user explicitly asks to "review the comments", "clean up", "wrap up", "tighten up", or "do a review pass". Also load if the user complains about AI-generated comment verbosity.
---

# Review pass: code-comment hygiene

AIs habitually generate verbose, restate-the-obvious code comments. The user finds this repeated failure mode painful enough to warrant a dedicated review pass before any AI-edited code is presented as complete.

## When this fires

Run this skill:
- after any autonomous chunk of work that produced non-trivial code edits, before declaring the work done
- before invoking the `commit` skill on substantive code changes
- on user request: "review pass", "clean up the comments", "wrap up", "tighten up"

## Scope: what to review

Review only:
- comments **added or modified in the current branch's diff** vs its base
- that were authored by an AI (you, or another AI in earlier turns)

Explicitly **out of scope** — leave these alone:
- projects where the user asks you not to run this skill ("this is unimportant code" or "we're just experimenting"), in projects that aren't production-ready/public-facing (personal scripts, etc)
- comments present before this branch started (human-written or human-authorised)
- TODOs and FIXMEs
- structured content; i.e. commented-out-code (although that's an antipattern, it's not *this* skill's problem); linter rules; anything consumed by external tooling - but only the *structure*. any prose within (i.e. a param's description) is potentially subject to this skill.

To find the eligible set, diff against the branch's merge-base. From a typical branch off `main`:

```
git diff $(git merge-base HEAD main)..HEAD
```

…and inspect the added/modified comment lines (`+` lines that are comment syntax in the file's language). Skip the rest.

## The rule

Source code should be self-documenting. Comments should be unnecessary.

**It's likely you will delete more than ~90% of eligible comments.** A subject-matter expert reading the well-named, well-structured code should not need them. Keep the remaining (say, ~10%) only when the comment captures something the code genuinely cannot make clear: a hidden constraint, a workaround for a specific bug, a non-obvious invariant, behaviour that would surprise a careful reader.

For each eligible comment, ask: *would a careful expert reader, looking only at the code, miss something important?*

- **No** → delete.
- **Yes** → rewrite for brutal brevity (see below) and keep.

Do not make structural/semantic changes to the code during this comment-review pass; but it's possible that a local/stylistic rewrite of the commented code would disnecessitate the comment - for instance, renaming a variable with a longer, clearer explanatory name; or introducing an intermediate variable/line-of-code to "name" an intermediate value that indicates why that value is necessary. (Especially for tight, arithmetic code.)

## Brutal brevity, when keeping

First pass:
- lowercase first character (unless proper noun), no trailing period if the comment is one line, etc — write in telegraphic style, not full sentences
- fragments are fine; full sentences are rare
- drop ceremony: "Note that…", "This function…", "We need to…"
- as few words as possible — just enough to call attention to the subtle thing

Only when absolutely necessary, for very complex scenarios that, say, involved an hour+ of research and debugging to arrive at and can never be made clear through code structure:
- colocate the research you think genuinely *must* be kept, into a *single* authoritative documentation comment defensively covering the situation
- which should be the *only* long, multi-sentence/multi-paragraph comment in the entire region of code

The latter will be very rare. Justify to the user why you think the complexity genuinely cannot be reduced through code structure, naming, and terse comments.

## Examples

Restating what the code does — delete:

```python
# This function returns the active users.
def active_users(users):
    return [u for u in users if u.active]
```

→

```python
def active_users(users):
    return [u for u in users if u.active]
```

Narrating the loop — delete:

```python
# Loop through each item in the list
for item in items:
    process(item)
```

Verbose "why" — keep, but rewrite:

```typescript
// We use setTimeout with 0ms here because we need to wait for the next event
// loop tick so that the DOM has time to update before we measure it.
setTimeout(() => measure(), 0);
```

→

```typescript
// defer to next tick so DOM commits before measure
setTimeout(() => measure(), 0);
```

Task narration - delete:

```python
# Added this to fix the bug where empty inputs crashed the parser
if not input:
    return None
```

## Also delete (when AI-added in this branch)

- `// removed X` markers for code that's already gone — git history is canonical
- section banners (`# === Helpers ===`, etc) unless already present in the git-history outside of AI work
- JSDoc/docstring prose (that just paraphrases the function signature or JSdoc params)

## Keep — even if you would otherwise strip

- TODOs and FIXMEs, no matter who added them
- any comment that already existed before this branch started
- comments the user wrote

## Reporting

The user wants every kept AI-generated comment **exposed and justified** in the final report so its judgement is auditable. Deletions are summarised in aggregate; keeps must be itemised.

Track during the pass:
- Which AI-comments you kept (file path, line range, the comment text after any rewrite, and the specific reason for keeping)
- Which AI-comments you deleted (count only)
- Any comments you skipped (non-prose structural/docstrings; user-added; etc)

At the **end of all work, in your final to-user writeup**, if there are any comments in the final version; include a `Kept comments` section in this format:

```
## Generated comments

- `src/parser/lexer.ts:142`
  > // defer measure to next tick so DOM commits first

  Captures a non-obvious DOM-paint-timing constraint. Without this, a reader might "fix" the `setTimeout(0)` as redundant.

- `src/utils/retry.ts:48-51`
  > // cap at 30s; server quotas reset every minute,
  > // a longer cap would starve the next quota window

  Relationship between cap value and server quota policy lives in external docs, not visible here. Surprising constraint worth flagging.
```

Required fields per kept comment:
- **`path:line` or `path:start-end`** — exact location, in-working-tree post-all-commits (so the user can jump straight there)
- **the comment text itself**, quoted verbatim, in a blockquote
- **a one-or-two-sentence reason** explaining what non-obvious thing it captures and why a future reader *needs* the call-out, and the failure-mode that keeping-the-comment avoids

Keep the reason specific. "It's a useful comment" is not a reason.

If there were no comments, or if there were, and you kept zero comments, say so explicitly:

```
(No comments to review.)
```

or

```
(Reviewed N eligible comments: deleted N, kept 0.)
```

This explicit zero is intentional — it confirms you actually did the pass rather than skipped it.

## When the report appears

- After autonomous work that included this pass: in the final to-user message wrapping up the work
- Before invoking the `commit` skill on substantive edits: include the report alongside the proposed commit message, so the user sees both at once
- On explicit user request: produce the report inline at that point

## Edge cases

- **Generated files**: skip entirely. If the file has a "do not edit" header or is in a known generated location (`dist/`, `build/`, `*.generated.*`), don't review its comments.
- **Vendor/third-party code**: skip. The branch may bring in vendored code with its own conventions.
- **Doc-comments / docstrings used by tooling**: a JSDoc that's consumed by `typedoc`, an OCaml docstring consumed by `odoc`, a Python docstring used by `pydoc` or `sphinx` — keep the tooling-useful components (i.e. parameters, tags, etc); this skill only applies to prose.
