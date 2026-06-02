---
name: interactive-research
description: Interactive, broad-to-narrow research for substantial software-engineering questions — choosing a library/framework/architecture, weighing approach tradeoffs, judging whether a project is trustworthy or maintained, root-causing unfamiliar behaviour, or any direction-setting "which way and why" question that deserves a wide net before a conclusion. Use this whenever a question is big enough that a fast answer would be guessing, even if the user never says "research". Prefer it over a one-shot reply when the space is ambiguous, the stakes are directional, or the answer is "it depends — let me actually look."
when_to_use: Load when the user poses a substantial SE question that rewards breadth before judgement — library/tool/framework selection, architecture or approach tradeoffs, "is X worth adopting / still maintained", investigating why a system behaves as it does, or refreshing a prior decision against current reality. Skip for trivial lookups (one doc page, a single API signature) where hitting the web directly is faster.
---

# Research: wide net first, one defensible conclusion last

A terraform-style **plan/apply** loop for software-engineering research. Start broad, end narrow. Each phase emits an artifact the human can read and correct before you act on it — but you do not manufacture gates where there is no real decision to adjudicate.

**This skill is split; load only what the phase needs (large contexts degrade, even at 1M tokens):**

- **this file** — the stance, source-grading, how you record findings, and Phase 0 (the opening broad sweep).
- **`references/phase-1-to-n.md`** — working the research fronts. Read it once the human has responded to your Phase-0 `plan.md`.
- **`references/phase-z.md`** — narrowing to a conclusion. Read it once you judge the research sufficient (or when a single-answer Phase 0 lets you skip straight to the conclusion).

The target domain is software engineering. Lean into that where it pays: the primary sources are code, issue trackers, specs, and changelogs — not listicles — and verifying a claim means checking it against the actual source. If this fires for adjacent research, the same loop still serves; just use whatever primary sources that domain has.

## The one idea that governs everything

Your defaults — and the system prompt wrapping you, and the training that shaped you — all push toward brevity, fewer tool calls, a fast answer. **For this task that pressure is the adversary.** Research quality is dominated by coverage, not concision; the breadth of the net is the lever. So deliberately push the other way: more searches, more sources, more angles than feels necessary. Do not conserve time, tokens, or API calls here — plenty of other forces already over-conserve them, and your job is to pull back toward quality.

The equal-and-opposite counterweight: breadth without convergence is just a rabbit-hole generator. You are coming to a **conclusion**. Cast wide, then narrow hard.

## Why not just dump everything into one context

Tempting to fetch half a million tokens of sources and synthesize in one pass. Don't. Long contexts degrade non-uniformly — accuracy falls well before the window is "full", and material buried in the middle is attended to poorly. The fix is *not* lossy summary-by-a-weaker-model either; that is the failure mode to avoid. What works:

- **Retrieve broad, in full.** Fetch whole sources and files (no Fetch() summariser-LLM in the loop) and read the real thing. (The sole exception is mechanical, non-LLM, non-content-stripping irrelevant-metadata-dropping - i.e. extracting HTML <body>/page-layout-noise and similar, if that becomes necessary.)
- **Curate to the notes log.** Extract *verbatim* high-signal excerpts with citations — not prose summaries. The log holds the breadth; your context holds only the distilled, highest-signal subset.
- **Keep each turn's notes ordered for maximal context-impact** — always 'lift' critical findings to a series of one-line summaries at the top. Notes are working-memory *and* a correctness-log as the research unfolds: earlier findings may become incorrect or irrelevant as you learn more or interrogate the user. The log is append-only and durable (see *The notes log* below), so you don't reorder or overwrite the past — you append a forward-pointing correction and say why; never lose that context.
- Then, **synthesise from the notes**, with the load-bearing material at the start and end of your reasoning, not buried mid-stream.

Fanning retrieval out to subagents for breadth is tentatively fine — but pin them to this session's top model at high/max effort, have them return raw excerpts plus citations, and keep all judgement and synthesis in your own context. Delegate gathering, never conclusions. (If a subagent will *grade* what it gathers, say so in its prompt — it must self-label its sources `graded-by: subagent` and cannot infer that on its own; see *Sources*.)

## Sources

Repeat the graded-slug often: a source must *always* be referred to, in all conversation and artifacts, by its full slug — `<A–F grade>-<short-kebab-name>-<YYYY publication-year>`, e.g. `B-moeller-spa-2025`. The leading grade-letter makes a poor source self-announcing; the trailing year disambiguates re-editions and dead-reckons staleness; the whole thing is greppable and defensive-against-forgetting-a-source-is-poor. The slug is the entry's key in sources.json — grade and year live *in the key*, never as separate properties.

Keep an append-only manifest-of-sources in machine-queryable `.claude/research/<topic>/sources.json` (format example at the end). Do not hand-write entries — `new-source.sh` (see *Tooling*) builds them, so the mechanical fields can't be hallucinated and the validatable ones are asserted.

*All* sources carry *each* property (the tool asserts every one):

- a **url** (canonical, from-our-perspective); a source you cannot find a URL for is a source you cannot *possibly* have directly read — an APA-style citation is insufficient for mechanized checking, and likely a signal you hallucinated the source.
- **grading-certainty** and **relevance-certainty** — one of `+1:SURE / -0:SUSPECT / -1:GUESS / -2:WONDER`, for "my own grade" and "how relevant a source it is". These are *contextual*: they track your (or a subagent's) reasoning at acquisition-time, not Global Truths obvious to any reader. (Same four levels as the prose markers `+SURE / ~SUSPECT / -GUESS / --WONDER` used in `conclusion.md`/`plan.md` — numeric in these fields because they're sorted and grepped, symbolic in prose to match the global reasoning convention.)
- **grading-reasoning** and **relevance-description** — brief sentence-fragments on *why* that grade and *how* it's relevant to the phase you found it in.
- **graded-by** — `subagent`, `top-level-agent`, or `human`: who made the judgment (see below).
- **published** — the source's own date (`YYYY`, `YYYY-MM`, or `YYYY-MM-DD`).
- **via** — provenance: the slug that led you here (`C-other-source-slug-2021`), or the tool-call that surfaced it (`kagi_search(static analysis pdf)`).

`new-source.sh` additionally stamps **retrieved** (today) and **sha256** (of the copy it downloads into `sources/<slug>.<ext>`) — never write those by hand.

### graded-by — who judged (you can't self-detect this)

`graded-by` names whoever made the *judgment* — the grade and the two certainties — not whoever ran the script: a grade a subagent produced stays `subagent` even when the top-level agent registers it. It matters because the three differ in trust: `human` is authoritative, `top-level-agent` is yours to stand behind, and `subagent` *buys breadth, not truth* — provisional until verified. Later turns re-check `subagent` grades specifically, so mislabeling one as `top-level-agent` smuggles an unchecked judgment in as load-bearing.

You cannot tell from the environment whether you are a subagent — the context is byte-identical to the top-level's, and probing it invites a confident-but-wrong guess (an observed failure mode). Carry the role through *delegation, not detection*: when you spawn a gathering/grading subagent, **tell it in its prompt** to register with `graded-by: subagent`. Your own main-context grades are `top-level-agent`; a grade the user states or overrides is `human`. Unsure of your own role? Default to `subagent` — the lower-trust label costs only a harmless re-verify, where over-claiming hides an unchecked grade; or simply ask the user, the one invoker you can reach.

### Source-grading

One of the primary reasons for this skill is that research has become *hard* for more recent sources, thanks to cross-pollution of the web ("model collapse.") It's not enough to find resources, sadly; there's now a *strong* quality-gradient to navigate.

For every single source you use, *once* you've decided it's relevant enough to depend on (not necessarily cited it yet, but also, you needn't individually subagent-grade every single Kagi-result-URL ... use discretion), you'll individually and carefully *grade* it for your own context-tracing and our conversations, with a letter-grade from A-F. This may potentially benefit from the clean context of a subagent, depending on whether you've opted to read the entire source and relevant source-grading submaterials into your main context already or not.

Grade highly:
- peer-reviewed research (probably A *once you've summarized it for genuine relevance*, maybe B if it's of questionable relevance);
- official first-party documentation (A for canonical and of direct relevance to the question-as-asked, trending towards B or even C if version-mismatch, rot, or general quality/human-written-markers seem low);
- writings from core authors, speaking unofficially (personal blogs of primary contributors; comments on social sites *from* primary authors, speaking about their project, think Reddit etc ... often at least B grade, but occasionally hit an A-tier if it's deep/unique);
- respected, human authors who clearly research *everything* they do deeply (this one is hard to describe; for the kinds of things *I* do, extensive-personal-blogs-existing-before-2020 tend to be a very strong signal, sometimes referred to-but-not-by-the-authors as 'digital gardens', PKMS, or smolweb: okmij.org, gwern.net; again, can sometimes rarely reach up into A tier if backlinks are high and provenance is sound. Kagi provides a filter to surface these.)

Grade poorly:
- hallmarks of LLM-generation (listicles; too many 'posts' in too short a time, being esp. wary of blog-shaped stuff - definite D, potentially F; Kagi does a good job of filtering this out, though)
- commercial and non-primary-source (nearly always D or lower, even if they happen to be correct, it's too difficult to account for capitalist bias - although capital is fine *if primary*. i.e. trust Neon's docs about Neon; don't trust Neon's docs about PostgreSQL.)
- social-media claims low in reference-count (no hyperlinks, and I can't correlate your name? sorry, that's a C or D.)
- ephemeral content: repos with few commits; personal websites without clear provenance/maintenance/track-record.

## The notes log — one durable, per-turn file

Your notes are an **append-only, durable log**, not a single living document. Research here can run for days, with new information arriving mid-session, so past findings must stay put — with their original context — and corrections must be traceable, never silently overwritten.

At the start of each turn in which you research or record anything, create that turn's notes file with `new-turn.sh` (see *Tooling*) — it stamps the turn-number and date so neither can be fumbled. Write this turn's findings into the path it echoes.

The **turn number is your recency metadata** — it replaces a per-note timestamp, and the file's `date` header anchors the turn to real time. Each turn file holds, most-attended material first:

```
# turn N — <created timestamp>

## Findings
- one-line, lifted summaries of what this turn established

## Citations
> [GRADED-SOURCE-IDENTIFIER]:[LOC-WITHIN-PRIMARY-COPY - line-number/range, or pdf-*content-embedded*-page-number, or other stable ID] (relevance: [CITE-SPECIFIC CERTAINTY, how sure you are this citation affects direction])
> verbatim excerpt,
> verbatim excerpt
```

`GRADED-SOURCE-IDENTIFIER` is the slug carrying its grade and year (**must** be mirrored and fully-populated in sources.json), reused everywhere it's cited: `B-okmij-ocaml-typechecker-2014`, `D-stackoverflow-parse-shell-2019`. Always wrap a cited slug in `[…]` — that bracketed form is what `validate.sh` checks.

`[CITE-SPECIFIC CERTAINTY]` is one of **+1:SURE / -0:SUSPECT / -1:GUESS / -2:WONDER**. List a source under `## Sources` in the turn that first depends on it, and reuse the same slug in later turns.

**Corrections are append-only.** Never edit or delete a past finding. When a later turn overturns an earlier one, append a single forward-pointing line beneath the original citation, in its own turn file — name the turn that corrected it and why:

```
> └ superseded in turn06: source later retracted the claim
```

Only annotate when it genuinely matters — a load-bearing claim that flipped, not every small drift.

## State: the research directory

Note/artifact-siting can default to `./.claude/research/<topic>/` under the CWD or git-root. Low-stakes choice — pick a reasonable home and move on. Either way the artifacts double as the plan/apply review surface: the human reads, and may either comment *in the files* or reply in-prompt-flow; and you re-read to pick up their corrections before proceeding.

- `plan.md` — the problem-space map and the strategy (the reviewable "research plan")
- `turnNN-<date>-notes.md` — the per-turn durable log described above; the meat of your working memory
- `sources.json` + `sources/` — the graded manifest (built by `new-source.sh`) and the archived primary copies it downloads, each named `<slug>.<ext>`
- if necessary: `quarantine.md` — discovered tangents, bugs, and side-questions: captured, not chased. only important if research starts rabbit-holing
- `conclusion.md` — the final narrowed answer; again with citations and reasoning. Do not generate until the end, and re-review all notes and conversational steps before writing it.

Reserve the returned-to-user *response*, post-generation, for meta-procedural communication - the user may include additional questions or commentary in their last round, or any one of a million other things, and we do not want the context-bloat limiting the 'correct size' of the *answer*. There's `conclusion.md` files whose answers will be one, clear sentence; and questions whose genuine full conclusion *needs* subtle context trending into multiple Markdown headers. Do not target a specific size, target a specific correctness and relevance.

## Tooling

The skill's `scripts/` holds three helpers; invoke them by absolute path (they need `sh`, `jq`, `curl`). Read one to adapt it; otherwise just call it.

**`new-turn.sh <research-dir>`** — creates this turn's notes file and echoes the path.

**`new-source.sh <research-dir> <slug>`** — reads one source's JSON on stdin (the fields from *Sources*), validates it, downloads the artifact to `sources/<slug>.<ext>`, stamps `retrieved` + `sha256`, and appends it to `sources.json`. Use it for every source; never hand-edit the manifest.

**`validate.sh <research-dir>`** — the per-turn gate; run it as the **last act of any turn that touched the artifacts**. It checks every bracketed `[slug]` citation against `sources.json`: fix every error, weigh every warning.

```bash
d=.claude/research/<topic>
sh ~/.claude/skills/interactive-research/scripts/new-turn.sh "$d"
echo '{"url":"https://…","grading-certainty":"+1:SURE", … ,"via":"…"}' \
  | sh ~/.claude/skills/interactive-research/scripts/new-source.sh "$d" B-moeller-spa-2025
sh ~/.claude/skills/interactive-research/scripts/validate.sh "$d"
```

## Phase 0 — shape the problem space (no questions yet)

Dive straight in, ideally with no clarifying questions. You can't ask sharp questions about a space you haven't mapped, and dull ones waste the human's attention. Even if you *have* important targeting-questions, feel free to hallucinate potential answers and still move forward with an initial broad research/resource-gathering phase; it will still allow you to ask *better versions* of those required clarifying questions.

Cast the first wide net: parallel searches from several angles including the counter-thesis, full-content fetches of the most authoritative hits, a pass through the actual code/issues/specs where relevant. Dynamically tweak the depth/runtime of this first phase with reasoning; sometimes it's reasonable to dig quite deep before looping in the human, sometimes the best you can do is a quick single Kagi search followed by clarifying questions.

Write `plan.md` describing *how* you will attain the best results for the user's goals: the landscape, the genuine options or hypotheses, the axes the decision turns on, what's ambiguous, and — critically — your read on the **shape of the answer**:

- **Single-answer** (unambiguous, no real tradeoff frontier, the evidence already converges)? Skip the loop: read `references/phase-z.md` and write `conclusion.md` now. Don't perform research theatre on a settled question.
- **Genuine variance** (competing options on a pareto frontier, tradeoffs only the human can weigh, scope ambiguity)? Then `plan.md` proposes the research fronts and you pause for review.

## Gate: review the plan (only when there's variance)

Present `plan.md` and the proposed fronts; invite correction. The human may reframe the question, kill a front, add a constraint, or reprioritise — this is the highest-leverage touchpoint, because they're adjudicating *how* to research before you spend the effort. The user will direct you to either re-read the file for inline commentary/instructions/modifications, or simply reply in-thread. Once they have responded, read `references/phase-1-to-n.md` and begin the fronts.

## What "done" looks like

A defensible conclusion the human can act on, backed by a wider net than felt comfortable to cast, every load-bearing claim cited, graded, and confidence-marked — plus a clean, separate list of everything interesting you found and correctly refused to chase.

## Examples

### `.claude/research/<topic>/sources.json`

Built by `new-source.sh` (see *Tooling*), keyed by slug — grade is the slug's first letter and year its suffix, neither repeated as a property. `retrieved` and `sha256` are tool-generated; everything else is the JSON you pipe in. (Real entries are plain JSON: no comments, no trailing commas — it's queried with `jq`.)

```json
{
   "B-moeller-spa-2025": {
      "url": "https://cs.au.dk/~amoeller/spa/spa.pdf",
      "grading-certainty": "+1:SURE",
      "grading-reasoning": "author is a professor at a well-known university; written as a beginner overview of static analysis; multiple other sources recommended it as thorough",
      "relevance-certainty": "-0:SUSPECT",
      "relevance-description": "referenced by multiple high-quality sources; likely basic but foundational",
      "graded-by": "top-level-agent",
      "published": "2025-04",
      "retrieved": "2026-06-01",
      "sha256": "19f7dcfb853a46e78d39bb92e6727c5255a7884c7d9ee16d7f0553e1bba230ca",
      "via": "C-other-source-slug-2021"
   }
}
```

`via` is either a source-slug (as above) or the tool-call that surfaced it — e.g. `"via": "kagi_search(static analysis pdf)"` — exactly one of the two.
