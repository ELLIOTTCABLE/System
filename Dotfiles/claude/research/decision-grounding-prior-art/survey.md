# Prior-art survey — decision-grounding for engineers ("science for non-scientists")

Stage-1 deliverable. Ephemeral (`.claude/`). Feeds stages 2–4 (durable `Research/`, the SKILL, the docs).
Organized by MECHANISM (the "move" each method makes), with a cross-map to the question-type typology.
Load-bearing claims carry certainty markers; sources are referred to by graded slug (full index: `sources.json`).
Two headline empirical claims (Dhami ACH RCT; deep-research-agent reference-hallucination rates) were
re-verified verbatim in main context, not just via subagent.

---

## Headline (read this first)

1. +SURE — The acid test the build is premised on ("force a ground-truth anchor; commit hypotheses/analysis
   before seeing the data") is NOT an invention; it is one mechanism independently reconverged across ≥5 fields
   over ~130 years: multiple working hypotheses (`A-chamberlin-multiple-hypotheses`, geology 1890) → strong
   inference (`A-platt-strong-inference`, 1964) → exploratory-vs-confirmatory (`B-tukey-eda`, stats 1962/77) →
   blind analysis (`B-klein-roodman-blind-analysis`, particle physics 2005) → forking paths / preregistration
   (`A-gelman-loken-forking-paths` 2013, `A-nosek-preregistration-revolution` 2018). The early nodes are
   genuinely independent. That convergence is strong evidence the mechanism is real, not disciplinary fashion.

2. +SURE — Across the LLM/agent bucket (b), the form-vs-substance gap is near-universal: every system surveyed
   substitutes a SELF-REFERENTIAL signal (self-cite-checking, an in-house LLM "reviewer", an LLM-vs-LLM debate
   Elo) for an external ground-truth anchor. The only artifacts in the entire corpus that PASS the acid test are
   the external CRITIQUE papers, never the systems they critique.

3. +SURE — The self-critique is now an empirical fact, not a worry. The closest human analogue to "a checklist
   that makes you more rigorous" — the intelligence community's structured analytic techniques — has been
   RCT-tested (`A-dhami-ach-rct`, n=50 practicing analysts, ground truth) and found to give NO accuracy benefit
   (36% vs 33% correct) while plausibly INCREASING inconsistency and inducing base-rate neglect (12% vs 52%).
   Its own designers concede the gap (`B-cia-tradecraft-primer`: "no guarantee of analytic precision or accuracy
   ... improve[s] the sophistication and credibility"). "Structure-shaped" ≠ "bias-reducing."

4. +SURE — Neither of the skill's two intended novel properties has prior art in the agent-skills ecosystem
   (`B5` sweep): no published skill (a) refuses-by-question-type, or (b) emits an adversarial prompt for the user
   to run in a SEPARATE context window. Every independence mechanism found is in-session. The nearest neighbours
   (`A-mythos-skill`, `B-idea-evaluation-skill`, `B-redteaming-analysis-skill`) implement pieces, never the whole.

5. ~SUSPECT — Therefore the skill's honest value proposition cannot be "this makes you less biased" (unproven for
   the analogous tradition). It must rest on three differently-grounded legs: structural pre-commitment (sound by
   CONSTRUCTION, not by RCT), calibration/forecasting (the one RCT-backed component — `A-gjp-superforecasting`),
   and auditability/transparency (the one benefit even SAT critics concede) — plus refusal of ungroundable types.

---

## The acid test, and why it is well-founded

The test: does an artifact force (i) a defined frame/population/question, (ii) a ground-truth anchor (gold set,
held-out outcome, real-world adjudication), (iii) pre-commitment of hypotheses/analysis BEFORE the data, and
(iv) an independent adversarial check — or does it merely emit science-shaped prose with none of these?

This is well-founded because (i)–(iii) are the same anti-bias move re-derived independently:
- `A-platt-strong-inference` (A): devise ALTERNATIVE hypotheses, then a "crucial experiment ... which will ...
  exclude one or more"; the diagnostic question "what experiment could disprove your hypothesis?"
- `A-chamberlin-multiple-hypotheses` (A): hold a "family of hypotheses" so affection is divided; names the enemy
  — "an unconscious pressing of the theory to make it fit the facts, and ... the facts to ... fit the theory."
- `A-gelman-loken-forking-paths` (A−, working paper): the structural reason it matters — "researcher degrees of
  freedom do not feel like degrees of freedom because, conditional on the data, each choice appears deterministic."
- `A-cos-preregistration` (A−) / `A-nosek-preregistration-revolution` (A): the operational form — "the same data
  cannot be used to generate and test a hypothesis"; preregistration is "a plan, not a prison"; split-sample +
  decision-tree IF-THEN tactics make it engineer-usable.
- `B-klein-roodman-blind-analysis` (body extraction failed — see QC): the most engineer-shaped tactic —
  add a hidden offset / seal the signal region, fix every cut while BLIND, unblind only once the pipeline is frozen.

The minimal engineer version (from `A1`): (1) write 2–4 candidate answers incl. the boring null; (2) for each,
pre-state the observation that would kill it; (3) write the exact metric/query + decision rule before running;
(4) if you must explore first, split the data and label exploratory findings; (5) blind yourself to the headline
number while fixing the procedure; (6) report the losers too.

Crucial distinction (carry to all downstream stages): there are TWO traditions with TWO evidence bases.
- Tradition 1 — structural pre-commitment / blinding / multiple hypotheses (above). Works by CONSTRUCTION: if the
  analysis is fixed before the data, the data cannot be retro-fitted. A logical guarantee, not a psychology claim.
  ~SUSPECT caveat: preregistration's real-world efficacy is itself debated, and an LLM that "pre-commits" then
  does the analysis itself is weaker than an external registry.
- Tradition 2 — debiasing CHECKLISTS as training (the SAT/ACH tradition). Empirically UNVALIDATED, partly
  INVALIDATED (see self-critique). The skill must lean on Tradition 1 and stay skeptical of Tradition 2.

---

## Bucket (b): form-vs-substance critique of LLM/agent "research/science/decision" systems

Verdict scale: forces-rigor | partial | science-shaped-prose. Every (b) system lands at partial-or-worse.

### Deep-research agents (OpenAI / Gemini / Perplexity) — VERDICT: science-shaped-prose
- +SURE They are retrieve→reason→synthesize→cite loops with an ADAPTIVE plan that forms hypotheses FROM the data
  — the inverse of pre-registration (`B-openai-deep-research`: "pivoting as needed in reaction to information it
  encounters"). No gold set, no exploratory/confirmatory split. `B-deep-research-agents-survey` (B): benchmarks
  even reward answering "directly from memory, bypassing any research procedure."
- +SURE The grounding failure is measured, not asserted (`A-reference-hallucination-dr`, A, main-context-verified):
  3–13% of citation URLs are hallucinated (never existed); deep-research agents hallucinate MORE than plain
  search-augmented LLMs (10.7% vs 4.8% pooled; Gemini DR worst at 13.3%); for several models EVERY non-resolving
  URL is fabricated. The one acid-test-PASSING artifact here is this critique paper itself (pre-stated RQs,
  defined population, Wayback ground-truth oracle, bootstrap CIs, adversarial self-audit). This directly vindicates
  the build's "no-URL = hallucination" source discipline.
- Best partial precedent: Gemini's "collaborative planning" scopes the question — but stops short of an anchor.

### Automated scientists — VERDICT: science-shaped-prose (with thin, real, hand-curated appendages)
- Sakana AI-Scientist (`B-sakana-ai-scientist`, first-party): success metric is "passes our automated reviewer" /
  clears a 60–70%-acceptance ICLR workshop — never "matches a held-out gold set." v2 ships validation knobs
  (`k_fold_validation`, `expose_prediction`) that are explicitly DISABLED. The independent eval
  (`A-sakana-ai-scientist-critique`, A−) ran it: ~half the experiments fail; 4/7 manuscripts had hallucinated
  numbers; it "failed to re-run the baseline, making its novel approach appear superior — an impossible outcome";
  its self-reviewer rejected 9/10 real papers incl. 4 that were accepted.
- Google AI co-scientist (`B-google-coscientist-arxiv`): the self-improvement loop optimizes an Elo the authors
  themselves disclaim — "the Elo metric is auto-evaluated and not based on independent ground truth ... may favour
  results [that] do not ... align with ... accuracy." Real external validation is a thin wet-lab layer (one novel
  in-vitro AML hit; liver-fibrosis deferred; the AMR result is a RE-derivation of the team's own prior answer).
- +SURE Lesson: an artifact can emit the ENTIRE form of science — hypotheses, experiments, figures, citations,
  even a real peer-review acceptance — with no mechanism that anchors ground truth or separates exploratory from
  confirmatory.

### LLM reasoning/verification patterns — VERDICT: reasoning-shaped-prose (one partial exception)
- +SURE Self-verification cannot substitute for an external anchor. `D-self-consistency` (D): authors concede the
  model "is not well calibrated and thus cannot distinguish well between correct ... and wrong solutions."
  `C-cove` (C): "the model is used to check its own work" (no tool use), and verification is post-hoc on an
  already-drafted answer. `C-tree-of-thoughts` (C−): LLM self-evaluation steering, wins ride on intrinsically-
  checkable toy tasks. Partial exception: `B-react` (B) grounds the loop in a real external environment, and
  `C-reflexion` (C+) earns its keep only when the evaluator is a real compiler/test, not an LLM judge.
- +SURE `A-potemkin-understanding` (A) closes the loop: models define concepts correctly 94.2% of the time but
  apply them wrongly (potemkin rate 0.40–0.55) and show 22% incoherence with their OWN outputs — direct proof
  self-verification cannot certify correctness. `A-leaderboard-illusion` (A−) supplies the Goodhart half:
  benchmark wins overstate capability once the measure becomes the target.

### Agent-skills ecosystem (the most direct prior art) — VERDICT: prose-scaffold, with two emerging species
- +SURE Anthropic's own Skills guidance (`A-anthropic-agent-skills`) says essentially NOTHING about epistemic
  rigor; its exemplar analysis skill ("Research synthesis workflow") is a bare 5-step prose checklist. The house
  style for analysis skills IS the prose scaffold the acid test condemns. ("Build evaluations first" validates the
  skill ARTIFACT, not the decision it grounds.)
- Two species exist, and NO published artifact unifies them:
  · pre-commitment/falsification: `A-mythos-skill` (A−, nearest neighbour overall — reference-class base rates,
    ACH matrix, calibrated confidence, anti-laundering "absence of evidence ≠ evidence", "strongest H ≠ confirmed
    H"); `B-idea-evaluation-skill` (B, pre-registered kill criteria: "State what specific evidence would falsify
    the GO decision within 90 days"); `B-solve-skill` (B−); superpowers `systematic-debugging` (C+).
  · adversarial/red-team: `B-redteaming-analysis-skill` (B+, full IC/Heuer canon — "Your assessment must survive a
    hostile reading by someone with the same evidence and a different prior"); `C-llm-council-skill` (C, anonymized
    peer review kills positional bias); superpowers `requesting-code-review` (C, context-isolated sub-agent).
- +SURE/~SUSPECT The two intended novel properties have NO precedent:
  · (A) refuse-by-question-type → none found. Skills gate on missing inputs, task-phase, or trivial triggers —
    never on the epistemic TYPE of the question.
  · (B) separate-context, user-pasted adversary → none found. All independence is in-session. The nearest principle
    is superpowers' "[the reviewer] should never inherit your session's context," extended from a programmatic
    sub-agent to a human-run fresh window — which nobody has published.
- ⇒ The build's novelty is integration (anchor + pre-commit + INDEPENDENT adversary, domain-agnostic) plus those
  two properties. The constituent moves have partial prior art and MUST be credited, not claimed as invention.

---

## Bucket (a): the human methodologies, by mechanism → typology cross-map

| Mechanism (the "move") | Anchor(s) | Serves question-type | Evidence status |
|---|---|---|---|
| Route by problem structure | `A-snowden-cynefin` (A): match method to clear/complicated/complex/chaotic; "disorder → break down and assign to the other four" (the router itself) | the meta-stage / all | framework, durable, not RCT'd |
| Scale rigor to reversibility | `A-amazon-one-way-door` (A): irreversible → deep analysis; reversible → act on ~70% of data | effort budgeting | industry practice |
| Pre-commit before data + multiple hypotheses | `A-platt-strong-inference`, `A-chamberlin-multiple-hypotheses`, `A-cos-preregistration`, `B-klein-roodman-blind-analysis`, `A-gelman-loken-forking-paths` | exploratory; confirmatory discipline | Tradition 1 — sound by construction |
| Bounded secondary research | `A-ganann-rapid-reviews` (A): time-boxed SR; state methods, mark interim, don't drop quality assessment | already-answered-in-literature | method established |
| Bounded estimation | `A-hubbard-measure-anything` (A−): decompose → calibrate (90% CIs) → Value-of-Information → measure highest-VoI only; Rule of Five | estimation (how-often/what-fraction) | calibration RCT-backed; rest decision-theoretic |
| Calibrated forecasting | `A-gjp-superforecasting` (A): 1-hr training improved accuracy, PERSISTED ≥1yr; aggregate beat control >60%, beat classified analysts 25–30% | estimation / prediction | the ONE RCT-backed leg |
| Refuse: causal needs a design | `A-hammerton-munafo-causal` (A): observational data underdetermines causation (missing-data problem; confounding/selection/measurement); "No single ... method ... can provide a definite answer to a causal question" | causal (REFUSE → "needs an experiment") | strong |
| Refuse: values not measurable | `A-gallie-essentially-contested` (B, QC): disputes "not resolvable by argument"; + `A-mchugh-kappa` (A) operational gate: κ<0.60 = inadequate agreement | values/definitional (REFUSE / NOT-MEASURABLE) | concept strong; primary unread |
| Validity bookkeeping | `A-shadish-cook-campbell-validity` (A−): statistical-conclusion / internal / construct / external — 4 one-line checks | all (quality gate) | ubiquitous classification, not an effect |
| Bias-control (held to its own critique) | `A-heuer-psych-intel` (A) ACH + `B-cia-tradecraft-primer` — see self-critique | (the cautionary case) | UNVALIDATED / partly invalidated |
| Metrics from goals (engineer bridge) | `B-basili-gqm` (B+); `B-kitchenham-ebse` (B+): the "Five A's" | operationalization | legible, not validated |

Typology coverage: already-answered, estimation, exploratory, causal, values — all anchored. ~SUSPECT GAP:
inaccessible-population is the weakest-anchored (partial via selection bias + Shadish external validity); a
survey-methodology coverage-error citation should be sourced in stage 3.

---

## The self-critique (headline finding; threads to README and SKILL body per the build directive)

+SURE The skill is, structurally, a member of a category whose efficacy has been tested and not demonstrated.
- `A-dhami-ach-rct` (A, RCT, main-context-verified): ACH gave no accuracy gain (36% vs 33%, n.s.), worsened
  within-analyst consistency, and induced base-rate neglect (12% vs 52% used base rates, p=.002). Fidelity
  collapsed: only 20% of trained analysts performed ACH's defining step. Authors: "consider ... alternatives."
- `A-chang-restructuring-sats` (A): "SATs have not been subject to sustained scientific testing of the sort that
  could reveal when they are helping or harming"; decomposition "may add noise."
- `A-rand-sat-assessment` (A−): commissioned BECAUSE validation is absent. (⚠ the paraphrase "no evidence they
  reduce biases" is NOT verified-verbatim RAND — robots-blocked; do not quote as RAND.)
- And `A4` extends it: even the broader toolkit (GQM, EBSE, the validity typology, Hubbard's AIE numbers) is
  sensible-but-unvalidated; only calibration/forecasting (`A-gjp-superforecasting`) has controlled effect sizes.

Our exposure and the honest defense:
- We CANNOT inherit "structured technique ∴ more rigorous" — that is exactly what the literature falsifies.
- Two caveats partly favor an LLM implementation (~SUSPECT, not proven): (1) an LLM follows a procedure with far
  higher FIDELITY than humans, so Dhami's dominant failure mode (80% non-compliance) may not transfer; (2) the
  better-validated debiasers (Morewedge feedback/practice; Bayesian information-structuring; consider-the-opposite)
  share features an LLM workflow can cheaply implement.
- Honest stance to encode: build a noise/bias-AWARE, disconfirmation-and-calibration-oriented workflow whose
  conceded value is AUDITABILITY + structural pre-commitment + honest refusal — explicitly NOT a validated
  debiaser — and treat the skill as a TESTABLE artifact (ground-truth eval), never an efficacy claim.
- README directive (verbatim intent): "This methodology has not been empirically validated. Comparable prior
  structured-analysis approaches have been actively invalidated. Tread carefully — there is no guarantee this
  yields the results you want." The SKILL body must keep the runtime LLM self-aware of this (a live stance, not a
  one-time disclaimer) — and, per the refined adversarial guidance, must NOT claim its separate-context adversary
  confers truth; it buys breadth, and the human verifies the survivors.

---

## Competing framings considered (the frontier, for re-weighing later)

- Survey spine: chose MECHANISM (+ typology cross-map) over pure-typology (would scatter the cross-cutting
  pre-commitment finding) and over by-discipline (most faithful to sources, least synthesized). -GUESS reversible
  if the human prefers the survey to mirror the skill's stage-1 router 1:1.
- Bucket-(b) depth: EXHAUSTIVE per direction; executed via 5 clean-context subagents. Diminishing returns were
  hit (the agent-skills sweep converged on two species after ~10 skills read in full + keyword sweeps).
- The skill's whole premise: the strongest counter-thesis (that structured techniques don't work) is now the
  survey's headline rather than a rebuttal target — the build proceeds with eyes open, not by ignoring it.

---

## Quarantine (interesting, deliberately not chased — triage for the human)
- Morewedge et al. 2015 debiasing-via-serious-games (effect persisted ≥2 months) — the best-validated debiasing
  intervention found; worth reading directly if the skill wants an evidence-backed debiasing component.
- `D-generalcompute-reasoning-cost` — reasoning patterns as an inference-COST story (2x/5x/20x); off-axis for
  epistemics but relevant if runtime cost becomes a design constraint. Provenance unverified (post-cutoff vendor blog).
- The "exploratory data analysis and confirmatory data analysis are the same thing" debate (Gelman, statmodeling
  2025) — a subtlety about whether the EDA/CDA split is clean; could refine the exploratory question-type.
- GQM+Strategies / Fraunhofer extension — if the skill wants an explicit goal→metric derivation sub-stage.
- Cochrane Rapid Reviews Methods Group (post-2010) — current rapid-review standards, newer than `A-ganann-rapid-reviews`.

---

## Source discipline notes
- Full graded index: `sources.json` (two-axis grades, certainties, URLs, dates). Per the stage-1 ephemeral scope,
  sha256/raw-collection are DEFERRED to stage 3 (the public skill's `sources/`), where the prompt mandates them.
- QC failures to resolve before any SKILL-verbatim citation (several official PDFs extract to garbage or are
  robots/paywall-blocked; clean text recovered from mirrors except where noted): `B-klein-roodman-blind-analysis`
  (body unread — paraphrase only), `A-heuer-psych-intel` (secondaries only), `A-rand-sat-assessment` (Kagi summary
  only; the "no evidence" paraphrase unverified), `A-gallie-essentially-contested` (primary unread — a keystone
  values-REFUSE cite, so per CLAUDE.md this is a show-stopper to resolve), `A-chang-restructuring-sats` (paywalled
  body; abstract verbatim), `B-basili-gqm` / `B-kitchenham-ebse` (PDFs unreadable; recovered via summary + HTML).
