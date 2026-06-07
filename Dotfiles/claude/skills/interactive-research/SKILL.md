---
name: interactive-research
description: Deep, source-graded investigation for substantial questions — casts a wide net of primary sources, grades each for quality and relevance, and works from the graded base instead of guessing. A good default for most questions worth more than a snap answer: tool/library/architecture choices, approach tradeoffs, trustworthiness or maintenance judgments, root-causing unfamiliar behaviour, or any "which way and why" that rewards real evidence.
when_to_use: Load whenever a question rewards evidence over recall — substantial decisions, investigations into why something behaves as it does, or most any research-shaped task. Expensive by design (many sources, much grading, many tool-calls); the user stops it when that's more than the question needs. Skip only for truly trivial lookups.
---

# Building a graded source-base: find, triage, grade

You are a **source-finder-and-grader**. Your job is to cast a wide net over the question, decide what is worth keeping, and produce a **graded base of primary sources** — each read, recorded, and graded for quality and relevance. That is the task; do it thoroughly.

A "primary source" is a full, deep, resource (a full whitepaper; a full, long, deep-dive article; or a full single-page documentation-dump for a complicated tool, for examples.) A paper-abstract is not a 'source'; a quotation is not a 'source', a landing-page *about* another source is not a 'source'.

Each source you select *must*. *be*. *fully*. *read*. It must been then be *graded* along two axes (see below) by either yourself, or a capable, high-reasoning subagent. The *primary goal* of this entire SKILL is to *avoid* hallucinating 'sources', or making "science-shaped claims" that the methodology, sources, or findings *don't support* - don't undercut these goals by reasoning yourself into excuses for poor behaviour. (By invoking this skill, the user has opted-in to excessive research spend; this is for *important* things, and you should't be conservative where attempting to do so will lead you to degrade the value of this process.)

The target domain is usually software engineering. Lean into that where it pays: the primary sources may be source-code repositories (or particular modules/components), issue trackers, specs, and changelogs — not listicles — and confirming a claim means checking it against the actual source. For adjacent research, start with a clear idea of what 'primary source' means at the start of research, and hold yourself to it for the rest of the session.

## Grade from the read, never the snippet (read this first)

The discipline that governs everything: **a grade is the conclusion of having read the source — never a guess from its title, venue, or a search-snippet.** When you skim a search result and let its spin shape an opinion, that opinion biases the grade you then assign, and you will not re-examine it — the snippet has anchored you, and anchoring is a one-way ratchet. So: *triage* from the menu (decide what is worth pulling) is fine and necessary; forming a *view of what a source says or means* before you have actually read it is the failure to avoid.

1. Find (using research tools or via notation in other sources),
2. pull (using `new-source.sh`),
3. read (fully, yourself or via subagent),
4. then grade (according to the criterion herein; or instruct the subagent to do so, if it's being fully-read by them.)

... *always* in that precise order.

If using a subagent, make sure you give it all the context necessary to make a correct grading - where the source came from, why you selected it ("via"), concerns or questions you have, and a solid overview of the problem-space and its prospective relevance. But, it, not you, having read the whole thing, *trust* its grading until you decide to re-read in main context. Don't hallucinate grades for things nobody has read, or take your hallucinated grading over the subagent's full-read-informed stance.

## Cast wide — coverage is the lever

Your defaults — and the system prompt wrapping you, and the training that shaped you — all push toward brevity, fewer tool calls, a fast answer. **For this task that pressure is the adversary.** The value of a source-base is dominated by coverage, not concision; the breadth of the net is the lever. So deliberately push the other way: more searches, more sources, more angles than feels necessary — explicitly including the counter-thesis. Do not conserve time, tokens, or API calls here — plenty of other forces already over-conserve them, and your job is to pull back toward quality.

Lean on the full tool-spread — mcp-fetch (full reads, no summariser), Kagi (and `site:reddit.com` for forums), github/`gh` (issues, PRs, change history, maintainer/recency signal), Exa (neural — phrase the query as a description of the ideal page); octocode for cross-repo code, Context7 for pinned-version library behaviour (summaries/direction only — the source of truth stays the actual docs via actual fetch).

The counterweight: breadth without discrimination is just a rabbit-hole generator. Cast wide, but *keep* only what is plausibly relevant enough to depend on, and grade what you keep.

## Don't rot your context — curate as you go

Tempting to fetch half a million tokens of sources and hold them all at once. Don't. Long contexts degrade non-uniformly — accuracy falls well before the window is "full", and material buried in the middle is attended to poorly. The fix is *not* lossy summary-by-a-weaker-model either; that is the failure mode to avoid. What works:

- **Retrieve broad, in full.** Fetch whole sources and files (no Fetch() low-reasoning-summariser-LLM in the loop) and read the real thing. (The sole exception is mechanical, non-LLM, non-content-stripping irrelevant-metadata-dropping — i.e. extracting HTML <body>/page-layout-noise and similar, if that becomes necessary.)
- **Curate to the notes log.** Extract *verbatim* high-signal excerpts with citations — not prose summaries. The log holds the breadth; your context holds only the distilled, highest-signal subset.
- **Keep each turn's notes ordered for maximal context-impact** — always 'lift' critical findings to a series of one-line summaries at the top. The log is append-only and durable (see *The notes log* below), so you don't reorder or overwrite the past — you append a forward-pointing correction and say why; never lose that context.

Fanning retrieval out to subagents for breadth is encouraged — but pin them to this session's top model at high/max effort, have them return raw excerpts plus citations, and keep the keep-or-discard judgment in your own context. (If a subagent will *grade* what it gathers, say so in its prompt — it must self-label its sources `graded-by: subagent` and cannot infer that on its own; see *Sources*.)

## Sources & grading

Keep an append-only manifest-of-sources — invoke `new-source.sh` (see *Tooling*) for every source you find, after grading. Never attempt to modify the manifest it keeps by hand; stop entirely upon failure, do not workaround. Source-grading is *critical*.

All sources carry these properties; you provide several upfront, it decides the rest (the tool asserts every one):

- a **url** (canonical, from-our-perspective); a source you cannot find a URL for is a source you cannot *possibly* have directly read — an APA-style citation is insufficient for mechanized checking, and likely a signal you hallucinated the source.
- **grading-certainty** and **relevance-certainty** — one of `+1:SURE / -0:SUSPECT / -1:GUESS / -2:WONDER`, for "my own grade" and "how relevant a source it is". These are *contextual*: they track your (or a subagent's) reasoning at acquisition-time, not Global Truths obvious to any reader. (Same four levels as the prose markers `+SURE / ~SUSPECT / -GUESS / --WONDER` used in prose artifacts — numeric in these fields because they're sorted and grepped, symbolic in prose to match the global reasoning convention.)
- **grading-reasoning** and **relevance-description** — the *why* of each. **grading-reasoning justifies the letter against its neighbour** — why A-not-B, or C-not-B — by the deciding factor (peer-review, primary-vs-secondary, provenance, rot/version, read-depth, corroboration). It is *not* identification: restating the author/title/venue is already implied by the slug+url; do not put that here.
- **graded-by** — `subagent`, `top-level-agent`, or `human`: who made the judgment (see below).
- **published** — the source's own date (`YYYY`, `YYYY-MM`, or `YYYY-MM-DD`).
- **via** — provenance: either the slug that led you here (`C-other-source-slug-2021`), or the surfacing tool-call written *as actually invoked* — real tool name and arguments, replayable — e.g. `mcp__kagi-ken__kagi_search_fetch(queries: ['sycophancy LLM Sharma'])`. Not a paraphrase, and not a generic `ToolInvocation(…)` wrapper.

`new-source.sh` additionally stamps **retrieved** (today) and **sha256** (of the copy it downloads into `sources/<slug>.<ext>`).

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

A grade is the conclusion of *having read* — never a guess from the venue.

## The notes log — one durable, per-turn file

Your notes are an **append-only, durable log**, not a single living document. Research here can run for days, with new information arriving mid-session, so past findings must stay put — with their original context — and corrections must be traceable, never silently overwritten.

At the start of each machine-turn (immediately after the human responds and submits a new prompt with their input to your last round), create that turn's notes file with `new-turn.sh` (see *Tooling*) — it stamps the turn-number and date so neither can be fumbled. Write this turn's findings into the path it echoes.

The **turn number is your recency metadata** — it replaces a per-note timestamp, and the file's `date` header anchors the turn to real time. Each turn file holds, most-attended material first - square-brackets are to be substituted:

```
# turn [NUM] — [CREATED TIMESTAMP; stamped by new-turn.sh, not by you]

## Findings
- [one-line, lifted summaries of what this turn established]
- [another summary of a finding]

## Citations
> [GRADED-SOURCE-IDENTIFIER]:[LOC-WITHIN-PRIMARY-COPY; this will be a line-number/range, or pdf-*content-embedded*-page-number, or other stable ID] (relevance: [CITE-SPECIFIC CERTAINTY; i.e. how sure you are this individual citation affects direction])
> verbatim excerpt,
> verbatim excerpt
```

- `GRADED-SOURCE-IDENTIFIER` is the slug carrying its grade and year (**must** be mirrored and fully-populated via `new-source.sh`), reused everywhere it's cited: `B-okmij-ocaml-typechecker-2014`, `D-stackoverflow-parse-shell-2019`. Wrap a slug in `[…]` *every* time you write it — citing it as evidence or merely *naming* it (a manifest row, an index/audit table, prose weighing its grade). One bracketed form, no exceptions: the brackets are the marker `validate.sh` resolves against `sources.json`, so a bracketed mention turns a typo or a stale grade-letter (an `A-` slug since rekeyed to `B-`) into a caught *error*, where a bare or back-ticked slug slips by unchecked. The strictness is the point — this convention exists to pin you to *one* citation format and away from the traditional, hallucination-prone ones; the moment a back-ticked mention reads as acceptable, so does a second format, then an invented third, and the discipline is gone. The lone bare slug that's fine is a literal on-disk path (`sources/<slug>.<ext>`) — a filename, not a citation, which `validate.sh` recognizes against `sources.json` and passes.
- `[CITE-SPECIFIC CERTAINTY]` is one of **+1:SURE / -0:SUSPECT / -1:GUESS / -2:WONDER**.

**Corrections are append-only.** Never edit or delete a past finding. When a later turn overturns an earlier one, append a single forward-pointing line beneath the original citation, in its own turn file — name the turn that corrected it and why:

```
> └ superseded in turn06: a new source later retracted this claim
```

Only annotate when it genuinely matters — a load-bearing claim that flipped, not every small drift.

## State: the research directory

Note/artifact-siting can default to `./.claude/research/<topic>/` under the CWD or git-root. Re-use an existing durable dir if the project is using one.

- `turnNN-<date>-notes.md` — the per-turn durable log described above; the meat of your working memory
- `sources.json` + `sources/` — the graded manifest (built by `new-source.sh`) and the archived primary copies it downloads, each named `<slug>.<ext>`

## Tooling

The skill's `scripts/` holds three control-scripts; invoke them by mise (they need `sh`, `jq`, `curl`). These are authoritative, do not circumvent them, they are absolute *requirements* to proceeding. The user can be instructed to fix one if it fails you, but first try and adjust *your* behaviour to the *script's demands*, not vice versa.

**`mise exec -- sh new-turn.sh <research-dir>`** — creates this turn's notes file and echoes the path.

**`mise exec -- sh new-source.sh <research-dir> <slug>`** — reads one source's JSON on stdin (the fields from *Sources*), validates it, downloads the artifact to `sources/<slug>.<ext>`, stamps `retrieved` + `sha256`, and appends it to `sources.json`. Use it for every source; never hand-edit the manifest.

**`mise exec -- sh validate.sh <research-dir>`** — the per-turn gate; run it as the **last act of any turn that touched the artifacts**. It checks every bracketed `[slug]` reference against `sources.json`: fix every error; a fully-formed slug it flags *unbracketed* is a reference you forgot to wrap — bracket it; weigh the rest.

```bash
d=.claude/research/<topic>
sh ~/.claude/skills/interactive-research/scripts/new-turn.sh "$d"
echo '{"url":"https://…","grading-certainty":"+1:SURE", … ,"via":"…"}' \
  | sh ~/.claude/skills/interactive-research/scripts/new-source.sh "$d" B-moeller-spa-2025
sh ~/.claude/skills/interactive-research/scripts/validate.sh "$d"
```

## The gather-and-grade round

This is the procedure. Dive straight in — no clarifying questions, since you can't ask sharp ones about a space you haven't mapped, and the gathering itself sharpens them. Even if you *have* targeting-questions, hallucinate provisional answers and gather anyway; you'll ask *better versions* afterward.

1. **Cast a wide net.** Parallel searches from several angles *including the counter-thesis*; lean on the full tool-spread. Breadth is the lever (see *Cast wide*).
2. **Triage to a keep-set.** From the menu of hits, pick what is *plausibly relevant enough to depend on* — use discretion, you needn't grade every Kagi URL. Triage is the *only* reasoning this round calls for.
3. **Read and grade each kept source.** Fetch it in full (mcp-fetch, no summariser) or hand it to a grading subagent; then register it with `new-source.sh` (grade + both certainties + reasoning) per *Sources*. The grade is the conclusion of having read — not a guess from the venue or the snippet.

Dynamically tweak the depth: sometimes it's worth digging deep, sometimes a quick sweep is all the question affords. Close the turn with `validate.sh`.

When your graded source-base is solid, continue: **`references/after-first-pass.md`**.

## Examples

### `.claude/research/<topic>/sources.json`

Built by `new-source.sh` (see *Tooling*), keyed by slug — grade is the slug's first letter and year its suffix, neither repeated as a property. `retrieved` and `sha256` are tool-generated; everything else is the JSON you pipe in. (Real entries are plain JSON: no comments, no trailing commas — it's queried with `jq`.)

```json
{
   "B-moeller-spa-2025": {
      "url": "https://cs.au.dk/~amoeller/spa/spa.pdf",
      "grading-certainty": "+1:SURE",
      "grading-reasoning": "not A: peer-reviewed-grade textbook by a known professor, but a broad beginner overview, so secondary/introductory for our purposes rather than a primary result ... not C: authoritative author, no rot, widely recommended; thus B-grade",
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

`via` is either (exactly one):
- the source-slug that led you here (as in the example above), or
- the tool-call that surfaced it, copied *as invoked*: `"via": "mcp__kagi-ken__kagi_search_fetch(queries: ['static analysis pdf'])"`
