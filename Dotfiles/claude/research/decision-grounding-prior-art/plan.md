# Research plan — prior-art survey for a "science-for-engineers" decision-grounding skill

Stage 1 of the `grounding-decisions` build. Ephemeral (`.claude/`), per your clarification.
This file is the plan/apply review surface: comment inline or in-thread; I re-read before the fronts.

## The question this survey must answer
*How is "letting a non-scientist engineer ground a decision in a wide reality-base while controlling
bias, in ~1hr–1day" already solved — by (a) established human methodologies and (b) existing LLM/agent
"research/decision/science" tools — and which of (b) actually force rigor vs. merely emit science-shaped prose?*

The acid test (from the prompt, and I now believe it is well-founded — see below): does an artifact
**force a ground-truth anchor and commit the analysis before seeing the data**, or not (no frame, no gold
set, no pre-registration)?

## Durable design constraints (settled with the human — carry to ALL stages, survive compaction)
- **Bucket (b) depth = EXHAUSTIVE.** Full form-vs-substance dissection of every major (b) artifact, not a
  sampled ~4. CONTEXT-WINDOW HAZARD acknowledged: fan the deep source-reads out to fresh-context subagents
  that return structured acid-test scorecards + raw key excerpts; keep all synthesis/judgement in main context
  (delegate gathering, never conclusions). Re-plan dynamically; split a front further if it threatens the window.
- **Self-critique is load-bearing, end-to-end.** The "structure-shaped ≠ bias-reducing; this skill is unvalidated
  and its closest prior-art (intel SATs) was actively *invalidated*" finding is the survey's headline AND must
  thread through to the productized deliverable:
    - README gets an explicit caveat header — paraphrase: *"This methodology has not been empirically validated.
      Comparable prior structured-analysis approaches have been actively invalidated. Tread carefully — there is
      no guarantee this yields the results you want."*
    - the SKILL.md body must keep the runtime LLM self-aware of this doubt (a live stance, not a one-time disclaimer).

## What Phase 0 established (high-confidence)
1. **The acid test is not the prompt-author's invention** — it is a convergent mechanism independently
   reinvented in ≥4 disciplines, which is strong evidence it's load-bearing:
   - preregistration / registered reports (psychology, post-replication-crisis) — `A-cos-preregistration`, `A-nosek-preregistration-revolution`
   - blind analysis (nuclear/particle physics: don't look at the answer until the analysis is frozen) — `A-cowan-roodman-blind-analysis`
   - exploratory-vs-confirmatory data analysis (Tukey) — `B-tukey-eda`
   - strong inference / multiple working hypotheses (Platt 1964, Chamberlin 1890) — `A-platt-strong-inference`, `A-chamberlin-multiple-hypotheses`
   The shared insight: **researcher degrees of freedom** (`A-gelman-loken-forking-paths`) silently launder
   noise into "findings" unless choices are committed up front.
2. **The prompt's refusal-typology maps onto real literature spines** (one per type) — so the meta-validative
   first stage can be grounded, not arbitrary. (mapping in turn01-notes.)
3. **A critical self-risk is already visible**: the intelligence community's structured analytic techniques
   (SATs) are the closest human analogue to "a checklist that makes you more rigorous" — and the best
   assessments (`A-rand-sat-assessment`, `B-chang-restructuring-sats`) say *there is little evidence SATs
   actually reduce bias*. "Structure-shaped" is not "bias-reducing." Our own skill is at risk of being the
   thing it critiques. This must be the survey's sharpest finding and carry into stages 2–3.

## The landscape (two buckets)
**(a) Human methodologies** — clustered by the role they'd play in the skill:
- *Routing / "what kind of question is this"*: Cynefin (`A-snowden-cynefin`), reversibility (`B-amazon-one-way-door`).
- *Pre-commitment / anti-forking-paths*: preregistration, blind analysis, exploratory-vs-confirmatory, strong inference.
- *Bounded secondary research* (already-answered type): rapid reviews (`B-rapid-review-methodology`),
  systematic reviews + evidence hierarchy/GRADE, evidence-based SE (`A-kitchenham-ebse`).
- *Estimation* (how-often/what-fraction type): Hubbard AIE (`A-hubbard-measure-anything`), calibration &
  forecasting (`B-tetlock-good-judgment`), reference-class forecasting (`B-reference-class-forecasting`).
- *Bias control / multiple hypotheses*: ACH + cognitive-bias taxonomy (`A-heuer-...`), SATs (`B-cia-tradecraft-primer`) — graded against their own critique.
- *Validity & measurement bookkeeping*: threats-to-validity typology (`A-shadish-cook-campbell-validity`),
  inter-rater reliability (`B-mchugh-kappa`), essentially-contested-concepts for the values/un-measurable type (`A-gallie-essentially-contested`).
- *Metrics framing*: GQM (`A-basili-gqm`); *decision analysis*: Smart Choices/PrOACT (`B-hammond-keeney-raiffa-smart-choices`).
- *Causal*: A/B testing / online controlled experiments (`B-kohavi-controlled-experiments`) as the thing a
  corpus cannot substitute for (→ the causal REFUSE type).

**(b) LLM/agent frameworks** — three sub-classes + the agent-skills ecosystem:
- *Deep-research agents* (OpenAI/Gemini/Perplexity): retrieve+synthesize, cite. `B-deep-research-agents-survey`.
- *Automated scientists*: Sakana AI-Scientist v1/v2 (`B-sakana-ai-scientist` + critique `A-sakana-ai-scientist-critique`),
  Google AI co-scientist (`B-google-co-scientist`).
- *Reasoning/prompt patterns*: ReAct/Reflexion/Chain-of-Verification/ToT (`B-react-reflexion-cov`).
- *Agent-skills ecosystem*: Anthropic SKILL.md (`A-anthropic-agent-skills`), obra/superpowers, claudeskills.org (octocode pending).
- *Cross-cutting critique ammo*: Potemkin understanding (`A-potemkin-understanding`), reference hallucination
  (`A-reference-hallucination-dr`), Nature on citation pollution, Goodhart/benchmark-gaming, generalcompute skeptic.

## Shape of the answer
**Genuine variance — so I'm pausing for this gate.** A survey isn't a pareto decision, but there are real
framing choices only you should make (below), and the prompt explicitly wants this interactive. Not a
single-answer skip-to-conclusion.

## Decisions — status
1. **Organizing spine — DECIDED (by me, under autonomy; veto-able).** Survey organized by **mechanism /
   the "move" each method makes**, with an explicit cross-map table to the refusal-typology for provenance.
   Rationale: the top Phase-0 finding (pre-commitment) is a cross-cutting mechanism that a typology spine
   would scatter; the self-critique is also meta/mechanism-level; bucket-(b) scoring = "does it implement the
   mechanism". If you'd rather have pure-typology or pure-discipline, say so and I'll restructure.
2. **Bucket (b) depth — SETTLED: exhaustive** (see Durable constraints). Context managed via subagent fan-out.
3. **Self-critique — SETTLED: headline + thread end-to-end** (see Durable constraints).
4. **Open questions are stacked in `questions.md`** (adversarial-prompting path, source-collection ceremony
   for the ephemeral survey, legal handling, repo gitignore) — not blocking; I proceed with reasoned defaults.

## Proposed fronts (Phase 1–n, after this gate)
- **F1 — pre-commitment family (deep reads):** Platt, COS/Nosek preregistration, Klein-Roodman blind analysis,
  Tukey EDA/CDA, Gelman-Loken. Extract the *transferable* pre-commitment mechanism + the failure it prevents.
- **F2 — routing & refusal grounding:** Cynefin, reversibility, Gallie + inter-rater reliability (values type),
  causal-inference/A-B (causal type), rapid-review (already-answered type), Hubbard/forecasting (estimation type).
  Verify each refusal-type has a real literature anchor.
- **F3 — bias-control & its limits (the self-critique):** Heuer/ACH + SATs vs. RAND/Chang critique. This is the
  front that protects us from building laundering. Highest scrutiny.
- **F4 — bucket (b) dissection:** fetch & read the ~4 representatives + critiques; score each on the acid test
  (frame? gold set? pre-registration? ground-truth anchor? or science-shaped prose?). octocode pass on the skills ecosystem.
- **F5 — SE-empiricism bridge:** GQM, EBSE/Kitchenham, validity typology — the "engineer already has some of this" thread.

## Source discipline for this stage
- Two-axis grading + slug-with-grade everywhere (done in notes); `sources.json` built *as I fetch* (tooling-generated
  sha256/retrieved — not hand-written).
- Load-bearing sources (esp. all of bucket b + the SAT critique + the pre-commitment classics) get
  full-methodology reads, in clean subagent context where it adds value — per the prompt's MANDATORY rule.
- Legal: `A-hubbard-measure-anything` full-book PDFs are pirated → pointer-only, gitignore, no push.
  `B-chang-restructuring-sats` paywalled (T&F) → pointer-only unless an open copy exists; I may ask you to fetch.

## Priority tension (per your CLAUDE.md — flagging it because it shapes direction)
Breadth-of-survey vs. depth-of-verification, under a "max effort but bounded" frame. The prompt mandates
full-methodology reads for load-bearing sources; an encyclopedic survey would dilute that scrutiny across too
many sources and undercut the very rigor the artifact is supposed to embody. I'm resolving it toward
**fewer sources, read harder** (depth), with a clearly-labeled catalog tier for breadth-without-deep-read.
If you'd rather maximize breadth (more methodologies named, each shallower), say so — it changes F1–F5 scope.
