---
name: prompt-review
description: Reviews prompt-engineering artifacts (SKILL.md files, CLAUDE.md, AGENTS.md) against a built-in checklist of effectiveness criteria for steering Claude, and proposes only substantively-justified edits with a brief rationale per change. The criteria carry a "criteria-as-of" date; when stale (>180 days), the audit still runs against the current criteria but recommends the user trigger the (separate, heavyweight) refresh procedure in a fresh max-effort session — refresh is never run inline. Explicitly designed to be token-expensive and slow; compounding value because the audited artifacts are read by Claude across many future sessions. Read after writing or substantively editing any SKILL.md, CLAUDE.md, or AGENTS.md.
when_to_use: Load after a non-trivial write or edit to a SKILL.md, CLAUDE.md, or AGENTS.md — treat as the default end-of-edit gate for those file types — or when the user asks to "review the prompt", "audit this skill", "validate the prompt", "is this skill effective", or similar. Skip on typo-only and formatting-only edits; the cost outweighs the benefit. Skip a freshly-`/init`-generated CLAUDE.md until the user has customised it.
---

# Prompt-review: audit prompt-engineering artifacts for effectiveness

This skill audits the user's prompt-engineering artifacts against an
embedded checklist of effectiveness criteria, and proposes only the
changes that meet a substantive bar. It is deliberately expensive: the
compounding value comes from those artifacts being read by Claude across
many future sessions, where small improvements pay back many times.

## When this fires

- after a non-trivial write or edit to any `SKILL.md`, `CLAUDE.md`, or
  project-local `AGENTS.md` — default end-of-edit gate for those types
- when the user asks to "review the prompt", "audit", "validate", or
  "check the effectiveness of" a skill or memory file
- when the user reports a skill mistriggering or behaving unexpectedly
  and asks what to change about its prompt

## When NOT to fire

- typo-fix-only or format-only edits to those files
- mid-stream in a multi-step edit session — wait for the natural break,
  then audit once for the whole session
- the user has explicitly said "ship it as-is" for the current edit
- a freshly-`/init`-generated CLAUDE.md, or a vendored / plugin skill
  the user didn't author

## Cost gating

Before firing:
- confirm the change is non-trivial (≥ a few lines of substantive prompt
  content; not whitespace, formatting, or link-only changes)
- if multiple files were written this session, batch them into one audit
  pass rather than one-per-file
- in interactive sessions, briefly state you're about to prompt-review
  and let the user say "skip"

## Procedure

### 0. Check criteria freshness

Criteria status: !`node ${CLAUDE_SKILL_DIR}/scripts/staleness.mjs`

Read the verdict on the line above (computed deterministically by a
helper script — don't try to do the date math yourself). Three cases:

- **FRESH** (≤ 90 days): proceed directly with the audit.
- **AGING** (91–180 days): proceed; flag in the report that the
  criteria are approaching staleness so the user can plan a refresh.
- **STALE** (> 180 days): proceed with the audit using the current
  criteria — stale guidance still beats no guidance for this run —
  but at the end of the report, surface a refresh recommendation
  (see the "Reporting format" section). **Do not refresh inline.**
  The refresh procedure (`REFRESH.md`) is heavy, slow, and produces
  research-shaped context that pollutes the user's working session;
  it belongs in a fresh dedicated session at maximum effort.

If the staleness probe fails or returns `UNKNOWN` (Node not on PATH,
SKILL.md unreadable, malformed `criteria-as-of:` line, etc.), treat
as AGING and note the probe failure in the report so the user can
investigate.

### 1. Identify the artifact(s)

Determine which file(s) the user just wrote or asked you to audit. If
ambiguous, ask. Read each fully.

### 2. Walk the criteria

Walk every criterion below against each artifact. Be honest: "satisfies"
is the most common outcome for a well-tuned file. Don't fabricate issues
to justify the run.

For each *potential* change, ask:
1. Is this substantively justified by a specific criterion?
2. Has the user's existing language already paired or ameliorated the
   concern in-sentence? (e.g., a bare-negative directive already
   followed by a positive companion is fine.)
3. Does the prompt-engineering benefit outweigh the churn cost? Marginal
   stylistic tweaks do not.

If the answers don't all favor the change, leave it alone.

### 3. Propose with rationale

For each substantively-justified change:
- show before / after
- one-sentence rationale tied to the criterion ID (e.g., "P1: bare
  negative without positive companion")
- confidence: SURE | SUSPECT | GUESS | WONDER

If the user wants the underlying source, point them to the log entry
the criterion cross-references. Don't quote source URLs inline in the
report — that's what `log/` is for.

### 4. Apply per session mode

- interactive: present proposed edits; let the user accept individually
- autonomous (`ai/*` branch or `.claude-commit` sentinel): apply
  directly, but include the citations in the final report so the user
  can audit during rebase

## Audit criteria

**criteria-as-of: 2026-05-04**

IDs are stable across refreshes. The bracketed log reference points at
the refresh that introduced or last-touched the criterion; a curious
auditor can jump there for the source quote and URL.

### Frontmatter (SKILL.md)

- **F1.** `name` ≤ 64 chars, lowercase letters/numbers/hyphens; optional
  on Claude Code (defaults to directory name). `description` ≤ 1024
  chars; combined with `when_to_use`, capped at **1,536 chars** in the
  skill listing. `when_to_use` is a Claude-Code-specific extension —
  acceptable here. [log/2026-05-04-initial.md]

- **F2.** Description leads with the key use case. The cap above
  truncates the tail, so trigger phrases buried late may be lost.
  [log/2026-05-04-initial.md]

- **F3.** Description in **third person**. "I help you …" / "You can
  use this to …" cause discovery problems. Imperative form
  ("Process X", "Read this before Y") is acceptable third-person.
  [log/2026-05-04-initial.md]

- **F4.** "Pushy" descriptions: include explicit trigger phrases
  ("Read after writing X", "Use when the user mentions Y") to combat
  undertriggering. [log/2026-05-04-initial.md]

### Body shape (SKILL.md)

- **B1.** Body under 500 lines. Beyond that, push reference material
  into one-level-deep `references/*.md` or sibling files.
  [log/2026-05-04-initial.md]

- **B2.** Progressive disclosure: SKILL.md is the routine path;
  exception-path content (refresh procedures, deep references) lives in
  separate files linked from SKILL.md. References must be one level
  deep — Claude may partially-read nested references and miss content.
  [log/2026-05-04-initial.md]

- **B3.** Examples in Markdown code blocks are idiomatic; do not
  rewrite to `<example>` XML tags as a stylistic preference. Both the
  Anthropic-published `skill-creator` and the agent-skills
  best-practices doc use Markdown for in-skill examples.
  [log/2026-05-04-initial.md]

### Prompt style (all three artifact types)

- **P1.** Tell Claude what to do, not what not to do. Soft preferences
  phrased as bare negatives are the audit target — convert to positive
  form, or pair with a positive companion in the same sentence.
  **Carve-out:** hard safety prohibitions ("never push to remote",
  "never commit secrets") appropriately stay negative.
  Cross-supported by peer-reviewed negation-blindness work; LLMs
  underweight negation tokens at the representation level.
  [log/2026-05-04-initial.md]

- **P2.** Aggressive-language calibration. On Opus 4.5+,
  CRITICAL/MUST-style framing tends to over-trigger; reserve for
  genuine absolutes. Normal "Use this when …" prompting suffices for
  ordinary directives. [log/2026-05-04-initial.md]

- **P3.** Explain the *why* behind non-obvious rules. Models generalise
  better from a one-line rationale than from a bare imperative.
  [log/2026-05-04-initial.md]

- **P4.** Imperative form in instructions. [log/2026-05-04-initial.md]

- **P5.** Concise — assume Claude is smart. Don't restate what the
  model already knows. Challenge each piece of information for whether
  it earns its tokens. [log/2026-05-04-initial.md]

- **P6.** No time-sensitive language ("until August 2025 use …"). Use
  a deprecated-section pattern instead. [log/2026-05-04-initial.md]

- **P7.** Consistent terminology — pick one term per concept and stick
  with it across the file. [log/2026-05-04-initial.md]

- **P8.** State scope explicitly. Opus 4.7 interprets prompts more
  literally and won't silently generalise an instruction from one item
  to another. If a rule should apply broadly, say so.
  [log/2026-05-04-initial.md]

### Skill mechanics (SKILL.md)

- **S1.** Skill content is loaded once and stays for the rest of the
  session — write standing instructions, not one-shot steps.
  [log/2026-05-04-initial.md]

- **S2.** Side-effecting skills (`/commit`, `/deploy`, `/send-x`) may
  warrant `disable-model-invocation: true`. Does **not** apply to
  skills that need to be model-invokable in autonomous workflows —
  flag, don't auto-recommend. [log/2026-05-04-initial.md]

- **S3.** Forward-slash paths only, even on Windows.
  [log/2026-05-04-initial.md]

### Workflows and choices

- **W1.** Use `[ ]`-checklists only for *complex* multi-step workflows
  with feedback loops, validation gates, or fan-out. Short procedural
  lists (3–7 simple steps without gates) don't benefit.
  [log/2026-05-04-initial.md]

- **V1.** Don't offer too many options. Provide a default with an
  explicit escape-hatch instead of presenting an alternatives menu.
  [log/2026-05-04-initial.md]

## Reporting format

End every audit with a structured report — itemise so the user can
audit the judgement (mirrors `review-pass`'s style):

```
## Prompt-review report

Criteria-as-of: YYYY-MM-DD (N days old)
Artifacts audited: <paths>

### Proposed edits

- `path/to/file.md:line-range`
  > before
  →
  > after

  Criterion: <ID> — <one-line restatement>
  Rationale: <one sentence on this artifact's specific failure>
  Confidence: SURE | SUSPECT | GUESS | WONDER

### Considered-and-rejected

- <one-line description> — rejected because <reason>

### Refresh recommendation (only when STALE)

> The prompt-review criteria are <N> days old (criteria-as-of:
> YYYY-MM-DD). Audit ran against current criteria, but they may be
> outdated relative to today's prompt-engineering best-practices.
> When you have the bandwidth, open a fresh session at maximum effort
> and ask for "the prompt-review research refresh"; the procedure
> lives in `prompt-review/REFRESH.md` and is intentionally heavy, so
> not appropriate to run inline in a working session.

(Omit this section entirely when the verdict was FRESH or AGING; for
AGING, a one-line note in the report header that staleness is
approaching is enough.)
```

If zero substantive edits emerged, say so explicitly:

```
(Audited N artifacts against M criteria; no substantively-justified edits.)
```

The explicit zero confirms the audit ran rather than was skipped.

## Notes

### True automatic-on-write triggering needs a hook

This skill loads when Claude decides the description matches the user's
intent. Strong description language pulls hard toward the
"after-writing-a-skill" trigger, but it's still Claude-decides, not
deterministic. For genuinely automatic firing on every Edit/Write to a
SKILL.md / CLAUDE.md / AGENTS.md, a `PostToolUse` hook in
`settings.json` is the right mechanism — invoke `/prompt-review` from
the hook. Surface this option to the user once; don't wire it
unilaterally.

### Relationship to `review-pass`

Distinct concerns:
- `review-pass` audits **code comments** in source-code edits
- `prompt-review` audits **prompt-engineering text** in SKILL.md,
  CLAUDE.md, AGENTS.md

A session that produced both code edits and prompt-artifact edits
should run both in sequence (`review-pass` on code, `prompt-review` on
prompts) before declaring done.
