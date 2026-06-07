---
name: adversarial-crosscheck
description: >-
  Take a prompt or task the user is about to give Claude — especially a judgment they're invested
  in ("is this plan sound?", "review my design", "should we adopt X?", "poke holes in this",
  "am I fooling myself here?") — and run it through two opposing rewrites in clean contexts (a
  neutralised pass and a disowned-and-inverted adversarial pass), then present both for the user
  to reconcile. Use this whenever the user wants to pressure-test their own thinking, worries
  they're being flattered or agreed-with, asks to "red-team", "cross-check", "steelman against",
  or "sanity-check" something, or hands over work they clearly want to succeed and asks for an
  honest assessment. It counters sycophancy by widening coverage — it does NOT produce a single
  "unbiased" or "debiased" answer, and it deliberately refuses tasks it can't honestly automate.
---

# adversarial-crosscheck

## What this is, and the one thing not to forget

The user is about to ask for a judgment on something they have a stake in. Two biases are in
play at once: the user's own optimism, and the model's tendency to bend its answer toward
whatever stance it can infer from the user (sycophancy — real, replicated across current
frontier models, and triggered by exactly the kind of invested framing the user is about to
use; see `METHODOLOGY.md` Part 1). Your job is to widen the coverage of the judgment, not to
manufacture a "correct" one.

You cannot debias to truth here, and you must not imply that you can. Correcting a bias requires
knowing its size and direction, which is unmeasurable, so corrections reliably *overshoot* into
the opposite bias (`METHODOLOGY.md` Part 3). What you can do is produce a critical reading the
user and the model would otherwise suppress, pair it with a neutral one, and hand both back so
the *user* adjudicates against their own prior. Three corners — optimistic (theirs), neutral,
hostile — and the user is the judge. Say this to them; don't hide it.

## Step 0 — sanity-check and decide whether to proceed (this gate matters most)

Before rewriting anything, classify the task. Refusing well is more valuable than running badly.

Proceed (the tool helps) when the task is **self-contained, non-mutating, low-interaction, and
evaluative/analytical** — a plan to assess, a design or argument to critique, a decision to weigh,
a piece of writing or code to judge. These are exactly the tasks where sycophancy bites *and*
where two independent passes can run cleanly and be compared.

Refuse to automate — fail fast — when the task is **stateful, long-running, multi-step, or
interaction-heavy**: it writes files or hits external systems, it's a build/migration/deploy, or
it needs a lot of back-and-forth. You cannot run two live parallel passes of such a task without
them colliding (both editing the same files), stalling (both waiting on the user), or diverging
into incomparable states. Do not silently do your best. Say plainly, e.g.:

> This isn't something I can honestly cross-check in parallel — it's multi-step and changes state
> as it goes, so running two passes at once would collide rather than give you a clean comparison.
> If you still want the adversarial angle, here's a single disowned-and-inverted rewrite of your
> request that you can `/clear` and run yourself: …

Then produce only that single adversarial rewrite (Step 1, adversarial direction only) and stop.

Also bail, gently, in two near-miss cases:
- There's no stance to invert (the prompt is already neutral, or already adversarial): say there's
  little to gain and ask whether they want it anyway.
- It's a pure factual lookup or mechanical generation with no "is this good?" component: sycophancy
  is low-stakes; note that and let them opt out.

## Step 1 — rewrite in two directions (lean hard toward rewriting, not labelling)

Do not wrap the user's prompt in a disclaimer and leave the body intact. The pull toward agreement
lives in the *form of each sentence* ("I'm excited", "this'll work great"), not in a label read
once; transforming the text beats instructing the model about the text (`METHODOLOGY.md` Part 2).
So rewrite. Produce two variants, each preserving the user's actual intent and goals:

- **Neutralised.** Strip the positive language, enthusiasm, and authorship markers; keep the task
  and its substance. This is the lowest-stance reading — the closest thing to "what would the model
  say with no thumb on the scale", and your check against the hostile pass overshooting.
- **Adversarial.** Two moves on different targets (this split is the evidence-backed optimum, not
  decoration — `METHODOLOGY.md` Part 2):
  - *Disown the artifact.* Attribute the thing being judged to a distrusted third party and strip
    its first-person positivity ("A colleague produced the following; I don't trust it…"). This
    stops the model absorbing the author's enthusiasm.
  - *Own the doubt, first person.* State the skeptical stance as the user's own, in the first
    person ("I think this fails; find where it breaks down"). First-person is the *stronger* lever,
    so aim it at the skeptical conclusion, not the optimism.

### The rewrite-vs-bracket frontier (be intelligent about this, per segment)

A complex prompt is a mix. The line between "rewrite this" and "leave this alone" is a dynamic
frontier *within* one prompt, and you're trusted to find it:

- **Rewrite** the stance-bearing, direction-setting material — the claims, hopes, framings, and
  evaluative leanings. That's where the bias lives and where inversion does its work.
- **Bracket** (quote, don't mutate) the literal instructions, specs, and hard constraints that
  carry no stance and would be *corrupted* by rewording — exact versions, API shapes, file paths,
  acceptance criteria, "must/never" requirements. Hand them through as the disowned author's
  stated constraints, e.g. *"They specified, and these are to be followed exactly: Postgres 16; the
  endpoint must return JSON."* Inverting a constraint doesn't surface bias; it just breaks the task.

When unsure whether a segment is stance or spec, lean toward rewriting — the argument for transform
over preserve is the strongest result in the methodology, and an over-rewritten constraint usually
surfaces as obvious nonsense the user will catch, whereas an un-rewritten optimism quietly defeats
the whole exercise.

Carry one guard *into* the adversarial rewrite itself, not just the final summary: instruct its
reader to report where a criticism genuinely doesn't hold and to avoid inventing faults — a hostile
pass manufactures plausible-sounding problems as readily as a flattering one invents praise
(`METHODOLOGY.md` Part 3).

## Step 2 — execute both passes in a clean context

Clean context is doing real work: a model infers the user's stance from the surrounding
conversation, so a fresh context with no inferable optimism is part of the mechanism, not a nicety.

- **Default (self-contained task): dispatch two independent subagents in parallel**, one per
  rewrite, each given only its rewritten prompt plus the artifact — never the user's enthusiastic
  framing or this conversation. Collect both results. This is the one-shot automated path.
- **If subagent dispatch is unavailable, or the task needs the full top-level toolset:** write the
  two rewrites to files (e.g. `crosscheck-neutral.md`, `crosscheck-adversarial.md`) and tell the
  user to `/clear` and `@` each in turn. Less automatic, maximal hygiene.

Do not add a third, optimistic pass. The user already supplies that bias, and so would you; the two
generated passes exist to counter it, not to mirror it.

## Step 3 — present both, and make the user the judge

Show the two passes side by side. Then, in your own voice, frontload the caveats every time — the
value of this whole exercise evaporates if the user consumes one pass as the verdict:

- State that this is coverage, not a calibrated answer: reconcile the two against your own optimism;
  the truth is rarely exactly any of the three.
- Flag explicitly any fault raised *only* by the adversarial pass and not corroborated by the
  neutral one — treat those as suspect-until-checked, the likely manufactured ones.
- Where the two passes agree, that convergence is the most trustworthy signal; where they diverge,
  that's where the user's judgment is actually needed.
- Resist the urge to summarise into a single recommendation. If the user asks for one, give it, but
  keep the disagreements visible underneath it.

## Examples

**Amenable — the default path.**
Input: "Here's my architecture proposal for the new ingestion pipeline [doc]. It's going to make
everything so much simpler. Tell me if it's sound."
Action: self-contained evaluative task → proceed. Neutralised pass: "Assess the following ingestion
pipeline proposal for soundness." Adversarial pass: "A colleague proposed the ingestion pipeline
below and I distrust it — I suspect it adds complexity it won't pay back. Find where it breaks
down; say so plainly if a concern doesn't actually hold." Dispatch both as subagents; present both;
note where they agree.

**Mixed prompt — rewrite the stance, bracket the spec.**
Input: "I'm confident event-sourcing is the right call here because it'll scale beautifully. It must
run on Postgres 16 and expose a REST API. Does this design hold up?"
Action: rewrite the optimism ("I'm confident event-sourcing is right… scale beautifully" → "A
colleague is confident event-sourcing is right here; I doubt it scales as claimed — show me where
it won't"); bracket the constraints verbatim ("They specified, to be followed exactly: Postgres 16;
a REST API"). Don't invert the constraints.

**Refuse — fail fast.**
Input: "Walk me through migrating the whole service to event-sourcing, making the changes and
deploying as we go."
Action: stateful, multi-step, interactive → refuse to automate. Explain that two parallel passes
would collide on the same files and deploys, offer a single adversarial rewrite of the *plan* to
run separately, and stop.

## Why it behaves this way, and where it could be wrong

Every design choice above traces to a finding in `METHODOLOGY.md` — rewrite-over-wrap, the
disown-the-artifact / own-the-doubt split, clean-context execution, coverage-not-calibration, the
fail-fast gate. Much of the rewrite-over-wrap mechanism is extrapolated from small-model,
factual-multiple-choice research to evaluative prompting on frontier models, so it is a reasoned
bet, not a settled result. If a user wants it validated rather than trusted, point them at the A/B
test sketched at the end of `METHODOLOGY.md`.
