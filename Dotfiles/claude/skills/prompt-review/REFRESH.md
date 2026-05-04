# Refresh procedure

How to re-research the prompt-engineering effectiveness criteria and
update `SKILL.md` accordingly. Triggered explicitly by the user — the
audit gate (`SKILL.md` step 0) only *recommends* a refresh when the
criteria-as-of date is stale; it never invokes this procedure inline.

## Run this in a dedicated session, at maximum effort

Refresh is the exception path. It involves wide web research, multi-step
synthesis, and reconciliation against existing criteria. Doing it inside
another task's session is poor UX:

- the research dumps lots of unrelated context into the conversation
  and can disrupt the user's actual work
- the multi-fetch budget conflicts with the original task's pacing
- max-effort settings appropriate for the refresh are wasted (and
  expensive) when shared with a cheaper task

So: when the audit reports STALE criteria, the agent should *recommend*
that the user open a fresh session at maximum effort and trigger this
procedure there. Do not run this procedure inline as part of someone's
working task.

The user's expected incantation is something like "refresh the
prompt-review research" in a fresh session.

## Anti-anchoring discipline (read first)

The single most important methodological point: **do not read past log
entries or the current criteria list during the exploration phase.**

If you start by reading `log/<latest>.md`, you will be primed on:
- *where* prior refreshes looked (specific URLs, venues, query terms)
- *what kinds* of findings they extracted

This is exactly the pink-elephant problem: the prior pattern becomes the
template you implicitly match against. The field genuinely changes fast
— first-party docs reorganize, new venues become relevant, fresh
research displaces old recommendations. Anchoring to last refresh's
source list will systematically under-cover those changes.

You already know roughly what this skill audits (you were invoked from
it). That's unavoidable. The achievable discipline is: do not consult
specific URLs, specific phrasings, or specific criterion IDs from prior
refreshes during exploration. Past work is a cross-check, not a starting
position.

## Three phases

### Phase 1 — Open exploration

Goal: discover *today's* state of the truth on how to write effective
prompt-engineering artifacts for Claude.

Constraints:
- do not open `log/`
- do not re-read `SKILL.md`'s "Audit criteria" section (re-read
  procedure / triggers / reporting if useful, but not the criteria
  themselves)
- stay in the main context window; subagents are inappropriate for this
  synthesis (per the user's research preferences). Use the most capable
  model and effort setting available.

What to search for:
- **First-party guidance** from the LLM vendor — current best-practices
  documents, the latest model's prompt-engineering page, any
  vendor-published example skills/agents that show idiomatic usage. Use
  whichever search and fetch tools are available; don't constrain
  yourself to URLs you might remember.
- **Peer-reviewed work** from roughly the last 18 months from today on
  prompt engineering, instruction-following, agent prompting, skill
  authoring, and adjacent topics. Prefer venues that publish reviewed
  NLP/ML work; treat preprints with care; treat blog posts as
  cross-reference only, not as primary evidence.
- **Practitioner artefacts** — well-regarded community examples and
  retrospectives. Useful for patterns, weak as evidence on their own.

Cast a wide net intentionally. Rank by relevance after fetching, not
during the search.

### Phase 2 — Synthesis

Goal: distill what you found into criterion-shaped statements,
independent of the prior criteria.

For each candidate criterion:
- one-line rule
- one-line rationale (what failure mode it prevents)
- the source(s) you found that support it
- the breadth (does it apply to SKILL.md only, or all three artifact
  types?)

Resist the urge to map onto the existing criteria IDs at this stage.
That mapping happens in Phase 3.

### Phase 3 — Reconciliation

Now, and only now, open `SKILL.md`'s current "Audit criteria" section
and the most recent entries under `log/`.

Diff your Phase-2 synthesis against the existing criteria. Each existing
criterion falls into one of three buckets:

- **Confirmed** — your fresh research independently found the same
  rule. Keep the existing ID; optionally tighten the phrasing if your
  research suggests a clearer formulation.
- **Updated** — the rule still holds but a numerical threshold,
  exception, or rationale has shifted. Edit in place; keep the ID;
  note the change in today's log.
- **Probable-retire** — the rule was not surfaced by your fresh
  research, or fresh research contradicts it. Investigate before
  retiring: is the absence because the rule is now considered obvious
  background knowledge (keep), because the underlying model changed
  and made it irrelevant (retire), or because your search missed it
  (re-search before deciding)?

Each new criterion you found that has no existing match becomes a new
criterion with a fresh ID. Use the prefix conventions (`F` frontmatter,
`B` body, `P` prompt-style, `S` skill-mechanics, `W` workflows,
`V` choices); add new prefixes if a genuinely new category appears.

Retired criteria do not get deleted. Move them to a "Retired criteria"
section in `SKILL.md` with a date and one-line reason — `(retired
YYYY-MM-DD: <reason>)`. This preserves the audit trail.

## Updating `SKILL.md`

After reconciliation:

1. Edit the "Audit criteria" section per the diff above.
2. Bump the `criteria-as-of:` date to today's absolute date (resolve
   any relative dates).
3. Update each criterion's `[log/...]` cross-reference if it was
   touched in this refresh.

## Writing today's log entry

Create `log/<YYYY-MM-DD>-<short-tag>.md` (e.g.,
`2026-11-15-routine.md`, `2027-03-02-anthropic-doc-rearrangement.md`).
The tag is for human scanability; choose something that hints at what
prompted or characterized this refresh.

The log entry is **append-only** and **whole-file**: write it once,
don't edit it later. If a future refresh discovers a mistake, that
correction goes in *that* refresh's entry, not retroactively in this
one. Provenance over neatness.

Required sections:

```markdown
# <date> — <short title>

## Inputs

- URLs fetched: <list, with brief one-line notes on what each yielded>
- Search queries used: <list>
- Other sources consulted: <transcripts, prior conversations, etc.>

## Findings

What was new, surprising, or distinctive about this refresh's
research. Be terse — the goal is to give a future cross-checker enough
to triangulate, not to write a thesis.

## Decisions

For each criterion change in `SKILL.md`:

- **F1 confirmed.** Phase-2 research independently surfaced the same
  rule.
- **P1 updated.** Threshold widened from X to Y because <source>.
- **W2 added.** New criterion: <one-line rule>. Source: <citation>.
- **V1 retired.** Reason: <one line>.
```

## After the refresh

If any criterion changed materially (added, removed, or substantively
reworded), schedule a re-audit of all existing user-authored artifacts:
every `~/.claude/skills/*/SKILL.md`, the global `~/.claude/CLAUDE.md`,
and any project-local `AGENTS.md` files in the current repo. Apply per
the session's interactive/autonomous mode.

Then self-audit `SKILL.md` against the refreshed criteria.

## What this procedure deliberately does not do

- It does not list specific URLs or venues to search. The methodology
  is source-agnostic precisely so future refreshes are not biased by
  this document.
- It does not specify which terms to use in queries. Phrase your
  searches based on the current state of the field, not on terms
  embedded here.
- It does not constrain the recency window beyond "roughly 18 months";
  if the field is moving slower or faster at refresh-time, calibrate.
