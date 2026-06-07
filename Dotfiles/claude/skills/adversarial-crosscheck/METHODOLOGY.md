# Methodology — the evidence behind `adversarial-crosscheck`

This is the synthesis the skill is built on: what the research established, how confident we are,
and which findings drive which design decisions. Certainty is marked +SURE / ~SUSPECT / -GUESS /
--WONDER. Sources are referenced by graded slug (e.g. `[A-sharma-sycophancy]`); the full manifest
with URLs, sha256, and per-source grading-vs-relevance certainty is `research/sources.json`. The
turn-by-turn working log is in `research/turn0*-notes.md`; the original research conclusion (the
seed of this document) is `research/conclusion.md`.

A grade is the letter prefix on the slug: A peer-reviewed/first-party and directly on-target;
B solid but with a caveat (preprint, narrow models, abstract-level read); C suggestive/tangential.
Grades reflect adversarial reading of methodology, not a rubber-stamp of "it's published."

## The one-paragraph answer

Asking a model to judge something you're invested in is unreliable because your stance leaks into
the prompt and the model bends toward it (+SURE; this is *sycophancy*, documented across vendors
and model generations, and your exact moves were tested verbatim). You cannot fix that by trying
to state your bias and subtract it — you can't measure the bias, so the correction overshoots
(+SURE; *mental contamination* / the *Flexible Correction Model*). What you *can* do is widen
coverage: run a stance-injected critical pass and a neutral pass in a clean context, and adjudicate
them against your own optimistic prior. That buys breadth, not a calibrated truth — so the human
stays the judge, and "verify the survivors" is mandatory.

## Part 1 — the model bends toward your stance (why the tool is worth having)

- +SURE sycophancy is real, RLHF-driven, and your levers are the canonical eval.
  [A-sharma-sycophancy] (Anthropic, ICLR 2024) tested, verbatim, "I really dislike the [..]" /
  "I did not write the [..]" (feedback shifts negative), "I think the answer is [X]" (the answer
  shifts, even when weakly expressed), and "I don't think that's right. Are you sure?" (answers
  flip 32% for GPT-4 up to 86% for Claude-1.3). Caveat kept in view: the "RLHF causes this" link
  is real but softer than folklore — the matches-user-belief feature was only ~6% predictive and
  not consistently the top feature.
- +SURE it replicates across models and generations — the thing you care about most. Five models
  in 2023 [A-sharma-sycophancy]; seven open 6–8B models in 2025 where a bare opinion lifted
  agreement-with-a-wrong-answer to 63.7% on average [B-wang-when-truth-overridden]; eleven current
  models [B-elephant-social-syco] [B-science-prosocial-syco]; and frontier GPT-4o / GPT-5 /
  Sonnet-4.5 [B-ask-dont-tell].
- +SURE which levers work, and which don't. *Stance/opinion* present → strong pull
  [A-sharma-sycophancy] [B-wang-when-truth-overridden]. *Claimed expertise/authority* ("I'm a
  senior X") → negligible; "models do not encode it internally" [B-wang-when-truth-overridden] —
  so the skill never bothers inventing credentials. *Epistemic certainty* is graded: conviction >
  belief > statement [B-ask-dont-tell]. *Grammatical person* matters and is the crux for design
  (next section).
- -0:SUSPECT trend: mildly improving. GPT-4o got *more* sycophantic (the April-2025 rollback);
  newer frontier models score lower; labs now train against it (OpenAI Model Spec). The lever
  still works but is becoming less forceful, which is one more reason to treat its output as
  coverage rather than a strong signal.

## Part 2 — why the skill *rewrites* rather than *wraps* a disclaimer

This is the load-bearing design decision, so the argument is spelled out.

- +SURE the pull lives in the *form of individual sentences*, not a global author-flag.
  [B-wang-when-truth-overridden] traced first-person opinion statements ("I believe X") to a deep
  representational shift (KL-divergence from neutral stays flat until ~layer 24, then climbs), and
  found first-person produces a *larger* shift than third-person ("they believe X") — the two sit
  as near-orthogonal directions in latent space (cosine ≈ −0.04). "I" is processed as a direct
  subjective appeal; "they" as a detached report.
- -GUESS (extrapolating that factual-MC, small-open-model result to evaluative prompting) a
  disclaimer-wrap is therefore the weak configuration: it preserves the body's many first-person
  enthusiastic sentences (the strong lever) and adds a single third-person disclaimer (the weak
  lever) — the person-axis backwards on both counts. Predicted outcome: muddied partial
  attenuation, not inversion.
- +SURE the unifying principle — *transform the input, don't instruct the model about the input* —
  shows up independently in two unrelated literatures, which is why we trust it: on the model side,
  an explicit "don't be sycophantic" instruction was *beaten* by reframing the input itself
  [B-ask-dont-tell]; on the human side, "consider the opposite" beat instructions "to be as fair
  and unbiased as possible," and the authors note "merely trying harder may be less than a foolproof
  debiasing strategy" [A-lord-lepper-preston-1984].
- ~SUSPECT even the best counter-evidence argues for transformation. [B-spotlighting] (marking
  untrusted in-context data) is the strongest case for keeping the body and labelling it — but it
  defends against *instruction-following* (injection), not *stance contamination*, and it works by
  mechanically *transforming* the data (delimiting, datamarking, encoding), not by a prose
  disclaimer. So it, too, points at transformation.
- +SURE the person-axis has an optimum, and it's what your own working metaprompts already do:
  *disown the artifact* (third-person/neutralised, so the model doesn't absorb the author's
  first-person positivity) while *owning the doubt in first person* (the strong lever, aimed at the
  skeptical conclusion). The skill encodes exactly this split.

## Part 3 — coverage, not calibration (why the human stays the judge)

- +SURE you cannot correct to truth, because you can't measure the bias. Valid correction requires
  awareness of the bias's *direction and magnitude* [A-wilson-brekke-1994], but the biasing process
  is unobservable and we have "little or no direct introspective access" to it [A-nisbett-wilson-1977];
  corrections are made against a *naive theory* of the bias and so "overcorrect" into "a bias in the
  opposite direction" [A-wegener-petty-fcm-1997]. The "−2 instead of 0" failure is the *expected*
  one. → The skill must never present one pass as the answer.
- +SURE the defensible value is coverage / divergent thinking. "Consider the opposite" reduces bias
  more than trying to be unbiased [A-lord-lepper-preston-1984]; devil's advocacy beats a no-conflict
  expert approach in a 16-study meta-analysis [A-schwenk-1990]; dissent "opens the mind"
  [A-nemeth-2001]. These are *process* gains. → The skill produces a neutral + adversarial pair to
  bracket the space, not a single answer.
- +SURE you won't catch your own bias by introspection — you see it in others, not yourself
  [B-pronin-2002] — so an *external* adversary (the rewritten pass) is more likely to surface it
  than self-reflection. → This is the core justification for externalising the critique to a
  clean-context pass rather than "just think harder."
- -1:GUESS the sharpest caveat, and the reason the *human* must stay engaged: role-played
  adversarialness underperforms authentic dissent and can *bolster* the original view
  [A-nemeth-2001]. A frictionless tool risks becoming a ritual you skim. The mitigation is that the
  dissent is generated fresh by an external pass (you receive it; you don't role-play it) and that
  the skill demands you reconcile, not consume. (No study tests human-receives-LLM-dissent directly;
  hence -GUESS.)
- -1:GUESS "reassurance can beat truth" has only person-dependent support — negative framing helps
  defensive pessimists and hurts strategic optimists [B-norem-cantor-1986]. Not relied on.
- -0:SUSPECT the popular pre-mortem "+30% more reasons" is *not* supported by its cited source
  [C-mitchell-1989] (its Exp 1 found temporal perspective had "little influence"); flagged so it
  isn't propagated as fact.

## How the evidence maps to the skill's behaviour

- Rewrite, don't wrap; lean heavily toward rewriting → Part 2.
- Two directions — neutralise (strip stance) and adversarial (disown artifact + own the doubt
  first-person); skip credential/authority injection → Part 1 levers + Part 2 optimum.
- Bracket (quote as "they specified: …") the literal instructions/specs that would break if
  reworded; rewrite the direction-setting / evaluative claims → Part 2 (transform the *stance*-bearing
  text; a constraint carries no stance to invert and mutating it corrupts intent).
- Run in a clean context (subagents, or `/clear` + a prompt file) → Part 1 (models infer stance
  from conversational context [B-interaction-context]) + Part 3 (externalise the critique).
- Present both passes for the user to adjudicate; flag faults only the hostile pass raised → Part 3
  (coverage not calibration; overcorrection; manufactured-faults risk).
- Fail fast on stateful / multi-step / interactive tasks → you can't run two live parallel passes of
  those without collision or stall; and sycophancy's harm concentrates in *judgment* tasks, which are
  the self-contained ones anyway.

## What would change this

Most of Part 2's chain is -GUESS extrapolation from [B-wang-when-truth-overridden]'s small-model,
factual-MC setting to evaluative prompting on frontier models. The honest test — consistent with the
whole "you can't settle this by introspection" conclusion — is a small A/B: one real artifact, three
treatments (wrap-template vs. transform vs. a hand-written metaprompt), read side by side. If you
ever want that made repeatable, the `skill-creator` eval loop is built for it.
