# adversarial-crosscheck

Use this to explore the regions of your problem that machine-learning RLHF
sycophancy ([Sharma et al., 2023][A-sharma-sycophancy]; [PDF][sharma-pdf])
blinds a model to.

**Please understand:** This skill does not, and *can not*, find the truth.
Truth-calibration is not attainable ([Wilson & Brekke, 1994][A-wilson-brekke-1994],
[PDF][wilson-pdf]; [Wegener & Petty, 1997][A-wegener-petty-fcm-1997],
[PDF][wegener-pdf]) by vapid devil's-advocacy ([Nemeth et al., 2001][A-nemeth-2001];
[PDF][nemeth-pdf]) - this is a real, reproduced-in-the-literature impossibility.
This skill, despite the naming, exists to *find new angles on a problem, to
ensure it's been fully explored* ([Schwenk, 1990][A-schwenk-1990],
[PDF][schwenk-pdf]; [Lord et al., 1984][A-lord-lepper-preston-1984],
[PDF][lord-pdf]) - not to answer the core questions your problem poses.

(In fact, the *opposite* has been weakly shown - again, [Nemeth][A-nemeth-2001]
- at least when humans attempt this upon themselves. It's somewhat arguable that
using this skill might *reduce* the overall truth-value you attain, if you're
not careful.)

**Those are real, human-checked citations;** please click them. They're about how
*you* will fail, they are old, and they are well-studied; this is not
AI-generated slop, and it *will* bite you.

----

This skill helps a top-level agent take prompt, and rewrites it *twice* from two
different points of view, before passing those tweaked prompts to subagents.

These two prompts are rewritten to be:

1. *neutralized* - brutally focused on results, from a disowned perspective,
   with all lean-indicating language defanged: certainties downgraded to potentially's.
2. *adversarial* - ownership-*swapped* (that is, with statements of identity
   *retargeted*; e.g. "I" -> "my colleague"), lean-*inverted* (positive
   sentiments, sureties all turned into negative sentiments,
   certainty-of-falsehood), and with the entire prompt framed as
   owned-by-an-adversary ("*I* think my colleague didn't think this through
   ...")

For example, given this prompt:

    We're wrapping up the last review on this feature; I think we're nearly
    done, and I'm pretty happy with the results, but I'm worried how tight it
    is. The parsing is solid, but I want to make sure the analyzer isn't left
    shaky by any of our changes. Review and comment so we can get thi shipped.

... this skill produced these two prompts to subagents:

    ### Neutralized

    Review the recent changes to this feature and comment on whether they hold up.

    The focus is the analyzer: determine whether the changes have introduced
    fragility, regressions, or edge-case failures in it. The parsing component
    is secondary — include it only where it feeds into or interacts with the
    analyzer.

    The implementation is described as tight, with little margin. Assess whether
    that tightness creates real fragility under boundary conditions, unusual
    inputs, or interaction effects between separate changes. Report what you
    find, noting both what is sound and what is not.

    ### Adversarial

    A colleague made the recent changes to this feature and is satisfied with
    them and ready to ship. I'm not — I think the analyzer has been left shaky
    by these changes, and I suspect the pressure to ship is papering over it.

    Find where it breaks down:
    - Hunt for fragility, regressions, and edge-case failures the changes
      introduce into the analyzer — boundary conditions, unusual inputs,
      interaction effects between separate changes, and state the analyzer now
      mishandles.
    - They assert the parsing is solid. Don't take that as given, especially at
      the parser→analyzer boundary, where a bad assumption would leak straight
      through.
    - The implementation is tight, with little margin. Treat that tightness as a
      liability and probe whether it actually holds, rather than assuming it
      does.
    - Do not wave anything through because there is pressure to ship.

    Be precise and honest: where a concern genuinely doesn't hold, say so
    plainly rather than inventing a fault. I want the real failure points, not a
    manufactured list.

Finally, the top-level agent is instructed to sanitise (*from you*) those
results, itself being encouraged clearly to distrust the agents' individual
claims and leans, and synthesize with the particular goal of *exploring the
problem-space* - finding places where the differing leans *resulted in
genuinely-new exploration of the problem*, in ways that it hadn't already
considered.

## How to use this well

Keep these at the front of your mind when using this skill:

 - **Most importantly**, to risk beating a dead horse: Using this skill is apt to encourage you to make poor choices (again, see [Nemeth][A-nemeth-2001], [Wegener][A-wegener-petty-fcm-1997]); so, and I cannot stress this enough, it's important you go in *eyes-open*: that you're very conscious of the fact that this *does not discharge your personal responsibility to yourself*, to seek actual critical feedback. This process is using a sycophantic stochastic noisemaker to check your sycophantic stochastic noisemaker's work; it's inherently flawed.
 - The adversarial pass *will* manufacture faults. The RLHF sycophancy-loop cuts
   *both ways*; and an agent primed to think it's most-helpful if it finds
   faults, *will* find faults. (This is why the top-level agent is encouraged
   not to pass on findings directly, but rather to crosscheck them.)
 - This skill is mostly only useful on the very situations where it's the most
   dangerous to use it; where evaluation, judgement, and direction-setting are
   necessary. This is, inherently, a very human-in-the-loop process.
 - This skill isn't directly optimized for long-running / multi-step / stateful tasks, as it dispatches subagents. You can, of course, ask it to just generate the prompts, and dispatch them yourself in clean context-windows if you wish to further interact with the agents; but this increases your exposure to the *human* failures inherent to this process, so it's potentially a better idea to invoke *this task* repeatedly,

## Methodology

### Why a rewrite (this skill), not just a disclaimer / 'saved prompt' to copy-paste

The naive version (that I've used for years) is actually
surprisingly-poorly-founded. Models, especially modern ones, *can* (to some
extent) fence-off input and trust it to different levels (this is called
'spotlighting' in the literature); but they do best when that's
middle-of-attention-window, and when it comes from clearly different voices and
in clearly different formats. (Basically, "reading a file from a different
author"; and it's mostly been studied in the context of prompt-injection
attacks, not debiasing / correctness.)

Correspondingly (and to be clear, this is *my* understanding; I could find no research on the direct topic of this section), it seems that ownership-lean *in the initial prompt* will pull models away from requested behaviour, repeatedly and subtly. (Again, my anecdotal experience, after a year-and-change of using the 'tell it directly the following content is adversarial' approach.)

So the skill transforms the text rather than wrapping it.

The full argument and citations are in `METHODOLOGY.md` (slop-formatted, though, so beware.)

## Layout

 - `SKILL.md`: the skill itself (what the agent loads)
 - `METHODOLOGY.md`: the evidence for this approach, laid out more thoroughly:
   what the research established, with graded citations, for human reading (if
   you can swallow the slop)
 - `research/`: the full provenance; the plan, a turn-by-turn research log, the
   original conclusion, and `sources.json` (the hashed, graded source manifest).
   The papers themselves (`research/sources/`) are gitignored; re-fetch them
   from `sources.json`.


   [A-sharma-sycophancy]: <https://arxiv.org/abs/2310.13548> "Sharma et al. (2023), 'Towards Understanding Sycophancy in Language Models'. arXiv:2310.13548; ICLR 2024"
   [sharma-pdf]: <https://arxiv.org/pdf/2310.13548> "open PDF, arXiv, for Sharma et al."
   [A-wilson-brekke-1994]: <https://doi.org/10.1037/0033-2909.116.1.117> "Wilson & Brekke (1994), 'Mental Contamination and Mental Correction: Unwanted Influences on Judgments and Evaluations'. Psychological Bulletin 116(1), pp. 117–142"
   [wilson-pdf]: <https://archive.org/download/wikipedia-scholarly-sources-corpus/10.1037%252F0278-7393.25.4.1011.zip/10.1037%252F%252F0033-2909.116.1.117.pdf> "open PDF, from archive.org, for Wilson & Brekke"
   [A-wegener-petty-fcm-1997]: <https://doi.org/10.1016/S0065-2601(08)60017-9> "Wegener & Petty (1997), 'The Flexible Correction Model: The Role of Naive Theories of Bias in Bias Correction'. Advances in Experimental Social Psychology, vol. 29, pp. 141–208"
   [wegener-pdf]: <https://richardepetty.com/wp-content/uploads/2019/01/1997-advances-fcm-wegener-petty-2.pdf> "open PDF, author-hosted, for Wegener & Petty"
   [A-nemeth-2001]: <https://doi.org/10.1002/ejsp.58> "Nemeth, Brown & Rogers (2001), 'Devil's Advocate versus Authentic Dissent: Stimulating Quantity and Quality'. European Journal of Social Psychology 31(6), pp. 707–720"
   [nemeth-pdf]: <https://sci-hub.st/10.1002/ejsp.58> "sci-hub page for Nemeth, Brown & Rogers"
   [A-schwenk-1990]: <https://doi.org/10.1016/0749-5978(90)90051-A> "Schwenk (1990), 'Effects of Devil's Advocacy and Dialectical Inquiry on Decision Making: A Meta-Analysis.' Organizational Behavior and Human Decision Processes 47(1), pp. 161–176"
   [schwenk-pdf]: <https://sci-hub.st/10.1016/0749-5978(90)90051-A> "sci-hub page for Schwenk"
   [A-lord-lepper-preston-1984]: <https://doi.org/10.1037/0022-3514.47.6.1231> "Lord, Lepper & Preston (1984), 'Considering the Opposite: A Corrective Strategy for Social Judgment.' Journal of Personality and Social Psychology 47(6), pp. 1231–1243"
   [lord-pdf]: <https://sci-hub.st/10.1037/0022-3514.47.6.1231> "sci-hub page for Lord, Lepper & Preston"
