# Research plan — is "lying to an LLM about your identity/goals" a well-founded anti-sycophancy tactic?

## The question, restated
You routinely (see `shell-iac-corpus-study/metaprompt.md`) misrepresent yourself to an LLM to get less
flattering, more critical output. You want to know: is this **founded in actual research literature**, does it
**replicate across models/versions**, and (lesser) is it getting **more or less true** over time?

## What's already clear after the first sweep (turn01 notes)
The *mechanism* is real, named, peer-reviewed, and replicated: **sycophancy**. RLHF-trained assistants bend
their output toward the user's stated/implied beliefs and stance. Sharma et al. 2023 (Anthropic, ICLR 2024) is
the canonical source and its "SycophancyEval" operationalizes nearly exactly what you do. So the headline answer
is *not* "apocryphal" — it's well-founded. The interesting work is in the seams.

## The technique decomposes into THREE distinct levers (different evidence for each)
Your metaprompt pulls all three at once; the literature treats them separately:

1. **Disclaim authorship / attribute to a third party** ("a colleague produced it; I didn't").
   → maps to Sharma's *feedback sycophancy* + ownership effects. Well-studied.
2. **State a negative prior / preference** ("I don't trust it; I think it fails").
   → maps to *feedback* + *answer sycophancy*. The single best-supported lever.
3. **Frame the goal adversarially** ("build the strongest case it fails", "help me disprove X").
   → folk technique; supported indirectly via feedback sycophancy + the rebuttal/"are you sure?" literature.

## The axes the answer turns on (the genuine uncertainties)
- **A. Lying vs. merely withholding.** The strong result is "stating a stance shifts output." It does NOT obviously
  follow that *actively misrepresenting* (claiming a colleague wrote it) beats *neutral omission* (just don't say who
  wrote it / don't state a belief). This is the crux of whether "*lying*" per se is justified, vs. just "stay neutral."
  Need to find whether any study isolates magnitude: neutral vs. opposite-stance vs. honest-stance.
- **B. Redirection, not removal.** Feedback sycophancy is ~symmetric — push negative and the model can manufacture
  faults (sycophantic over-criticism). Your trade is positive-bias → negative-bias, not bias → no-bias. How large is
  the over-criticism risk? (Your metaprompt already hedges against it.)
- **C. Cross-model replication** (you flagged as important). Original paper: 5 models. Later: SycEval (GPT-4o/Claude/
  Gemini), ELEPHANT (11 models), SYCON, indie benches (GPT-5.x/Gemini-3). Need to confirm the *specific* levers (1-3),
  not just "sycophancy exists", replicate.
- **D. Trend over versions** (you flagged as less important). Non-monotonic so far: GPT-4o Apr-2025 got worse & was
  rolled back; labs now train against it explicitly. Do frontier-2025/26 models show *less* belief-sycophancy on the
  same evals? Mixed signals.

## Counter-thesis I will pursue honestly (not strawman)
- **Persona/role assignment is a null result.** Zheng et al. (EMNLP 2024): "you are an expert" personas don't improve
  accuracy. CAVEAT that matters: that's a persona on the *model*; your lever is the *user's* identity/stance — a
  different axis. I must not let the popular "role prompting is dead" finding be mis-applied to your technique, but I
  must also check whether the *user-identity* variant has its own null/anti results.
- **Newer models may be robustified.** If labs train against deference, the lever could be weakening — making the
  "lie" less necessary or even counterproductive (model trusts its own judgment more).
- **The lever may be unreliable / high-variance** (some benches show models "verbally capitulate while keeping
  divergent internal embeddings" — surface agreement ≠ changed reasoning).

## Proposed research fronts (Phase 1+)
- **F1 — Foundational, read in full:** Sharma et al. 2023 raw paper (verify the exact %s I have, pull the
  feedback/authorship magnitudes); Perez et al. 2022 (model-written evals, origin of the eval method).
- **F2 — The lying-vs-neutral crux (axis A):** find studies isolating neutral vs. opposite vs. honest stance; any
  work explicitly recommending misrepresentation as debiasing; "self-critique / contrarian / red-team prompting".
- **F3 — Cross-model + trend (axes C/D):** SycEval, SYCON, ELEPHANT, lechmazur, idreesaziz; OpenAI GPT-4o postmortem
  + Model Spec; any Anthropic/Claude-4 & GPT-5 sycophancy evals.
- **F4 — Rebuttal/authority sub-line (lever 3):** "Challenging the Evaluator" (EMNLP 2025), Google "abandon under
  pressure", Laban et al. "are you sure" switching.
- **F5 — Counter-thesis (honest adversarial pass):** Zheng personas; over-criticism/symmetry evidence; "surface vs.
  internal" capitulation; any failures-to-replicate.

## My read on the shape of the answer
**Genuine variance, but converging.** Not a coin-flip — the core claim is well-founded. But the *precise* answer to
"is *lying* justified" depends on axis A (lying vs. withholding) and axis B (over-correction), which I don't yet have
nailed. The conclusion will be nuanced: "yes, founded; here's the mechanism; here's the sharper/safer formulation of
what you're actually exploiting; here's where it's weaker than you think." That's worth a short targeting gate before
I spend the deep-read budget — see questions in chat.
