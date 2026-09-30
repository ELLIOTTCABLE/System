# Stacked questions for the human (non-blocking; I proceed with reasoned defaults)

Raised during stage-1 prior-art survey. None blocks survey progress; each notes my default-in-motion.

1. **Survey organizing spine** — DECIDED by me: by-mechanism + typology cross-map (plan.md §Decisions).
   In motion. Veto toward pure-typology or pure-discipline if you disagree.

2. **Adversarial-prompting research path** (`[USER: insert path]` in prompt.md, design-property B).
   Not needed for the survey; needed for the stage-3 skill build. Where does this research live?
   Default: I'll ask again before stage 3.

3. **Source-collection ceremony for the EPHEMERAL survey.** prompt.md mandates collecting every cited source
   into `sources/` with QC'd text-extraction + tooling sha256. You scoped stage-1 as ephemeral `.claude/`.
   My default: build a full `sources.json` (two-axis grades, URLs, dates) but only generate sha256 / collect
   raw bytes for sources I actually download; defer the full collect-and-hash ceremony to stage 3 (the public
   skill's `sources/`). Tell me if you want full collection now.

4. **Legal handling (confirm).** `A-hubbard-measure-anything` full-book PDFs online are pirated → treating as
   pointer-only, no raw copy committed, leaning on legit summaries instead. `B-chang-restructuring-sats` likely
   paywalled (T&F) → pointer-only; may ask you to fetch if it proves load-bearing. OK?

5. **`.claude/` is not gitignored in this `System` repo** → ephemeral research shows as untracked. Suggest
   adding `/.claude/` (or `/.claude/research/`) to `.gitignore`. (Your git to mutate, not mine.)

6. **Human-as-tool asks** — primaries I could NOT read (image-PDF / robots / paywall); claims currently rest on
   mirrors/secondaries/abstracts. NOT blocking the survey (all corroborated), but should be resolved before any
   verbatim citation in the stage-3 SKILL. In rough priority:
   - `A-gallie-essentially-contested` — KEYSTONE for the values-REFUSE; primary un-extractable. Per your CLAUDE.md,
     "a PDF I cannot read" on a keystone cite is a show-stopper — please load Aristotelian Society 1956
     (doi:10.1093/aristotelian/56.1.167) interactively, or confirm the secondary is acceptable.
   - `A-rand-sat-assessment` — rand.org robots-blocked; AND the load-bearing "no evidence they reduce biases" line
     is a Semantic-Scholar paraphrase, NOT verified RAND text. Needs a human pull before quoting as RAND.
   - `A-heuer-psych-intel` (CIA PDF is image-only), `B-klein-roodman-blind-analysis` (body wouldn't decompress),
     `A-chang-restructuring-sats` (paywalled body; abstract verbatim only), `B-basili-gqm` / `B-kitchenham-ebse`
     (PDFs un-extractable, recovered via summary+HTML). The Python extractor at
     `~/Sync/Code/Dorc/.pdf-extract/dump_pdfs.py` may handle the image PDFs in stage 3.

7. **Adversarial-prompting research path** (design-property B, stage 3): ecosystem prior art now located
   (`B-redteaming-analysis-skill` ports the IC/Heuer canon; superpowers' context-isolated sub-agent) — but your
   OWN adversarial-prompting research (the `[USER: insert path]` placeholder in prompt.md) is still needed to
   build the separate-context adversarial stage. Point me at it before stage 3.

## Status
Stage 1 (prior-art survey) COMPLETE: see `survey.md` + `sources.json` (50 graded entries). Stopped at the
stage-1/stage-2 boundary per your instruction — no durable `Research/` work started. No git/external mutations.
