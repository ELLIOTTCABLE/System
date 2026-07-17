---
name: foreign-models
description: >-
   Dispatch a foreign (non-Anthropic) model as a subagent — OpenAI Codex/GPT-5.6-Sol, DeepSeek V4-Pro,
   or Google Antigravity — either as a write-authorized agentic worker in a worktree or a read-only
   reviewer. Codex and DeepSeek explore, edit when authorized, and self-report; Antigravity is a
   single-packet headless reviewer. Use when you (the conductor) want to offload agentic work to another
   harness, get a cross-lineage second opinion, or run a correlated-blind-spot check same-lineage Claude
   subagents can't give. This is the dispatch/wrapping layer — how to split work across foreign models
   of unequal intelligence, prompt each to its level, and wrap them safely to save tokens. Also where
   adversarial-crosscheck's foreign lane routes; not every dispatch is a crosscheck.
---

# foreign-models

Dispatch another model as a subagent — for raw capability (Fable), a decorrelated outside-lineage angle
(Codex/DeepSeek/Antigravity fail where Claude fails, so they catch what your lineage misses), or cheap
parallel breadth. You (the conductor) either consume a reviewer's output and adjudicate it, or hand a
worker a worktree and review its commits.

Prerequisite: per-machine setup is done (`INSTALL.md`). A missing binary fails loudly; install nothing.

## The stable — an intelligence/cost ladder, not a capability ladder

The capability FLOOR is even: Fable, Codex/GPT-5.6-Sol, and DeepSeek are all agentic — each explores a
repo, edits when authorized, and maintains its own report. What differs is **intelligence and cost**;
only Antigravity is genuinely single-packet. Pick by intelligence-needed vs. price, then prompt each to
its level.

- **Fable (Claude 5) — top capability, ~10× the cost, IN-lineage.** Dispatch as a native Agent subagent
  with `model: fable`. **Explicit human ack required before every use.** **Never run two Fables in
  parallel — at most one per task.** Same lineage as you, so it buys raw power, not decorrelation.
  Reserve it for the single hardest job; reserve it for *knowledge work*
  (planning, review, reasoning, adjudication), not code and not churning over
  tool-invocations and compilers.
- **Codex / GPT-5.6-Sol (foreign) — competent, fairly priced. The default first choice.** Full agentic
  worker; sandboxed on native Windows (`workspace-write`). Vaguely Claude Opus-class.
- **DeepSeek V4-Pro (foreign) — lower intelligence, effectively free. Almost always add in tandem.**
  Agentic explorer (nested Claude Code, Read/Grep/Glob across turns, scoped to the cwd subtree),
  write-capable when the wrapper allows it — but UNSANDBOXED (runs as you). Its near-zero cost is the
  point: a free second decorrelated angle. Lower raw-reasoning than Sol/Opus, but dirt-cheap; mildly
  distrust its output, but it can still find angles that other models miss. Where possible, check /
  verify its work and claims more thoroughly.
- **Antigravity (Gemini) — single-packet, tool-less, headless. Least-used; not recently exercised.**
  Cannot explore; inline everything. Treat as unverified; confirm before relying.

**Selection.** Sol first; DeepSeek almost always alongside it (free). Fable only on explicit ack.
Antigravity rarely. Precision ranking (for weighting findings): Fable > Sol > DeepSeek ≫ Antigravity.

## Prompt each target to its intelligence (inverse relationship)

More capable models want fewer words; less capable models want tighter rails.

- **Fable** — a paragraph; a couple of sentences. Explain the GOALS, not the steps — it works out
  what-to-do itself. Do NOT enumerate guardrails unless one is genuinely critical AND non-obvious
  (usually none). Overprompting degrades it. **Encourage it to delegate** to protect its very expensive
  tokens: spawn Opus-class subagents for complex exploration and code-authoring, Sonnet-class for
  mechanical grunt work — Fable orchestrates and reasons; it shouldn't burn its own context on legwork.
  If unsure the brief is right, have the human review it before dispatch — Fable is too expensive to
  waste on a bad or overconstrained prompt.
- **Sol (GPT-5.6)** — follows instructions well and is generally competent. It's okay to give it
  explicit guardrails IF any exist, but don't over-target or deeply enumerate; a clear goal plus the
  real constraints suffices.
- **DeepSeek** — lower intelligence: a NARROW brief with clear do/don't, and EXPLICITLY enumerate every
  constraint and guardrail. Make very clear what NOT to do — it won't reliably infer the bounds.
- **Antigravity** — fully self-contained and inlined (it can't explore); one packet, no file references.

**Only Fable delegates.** The foreign lanes (Codex, DeepSeek, Antigravity) work SOLO — tell them to do
the work themselves and NOT spawn further subagents (DeepSeek's wrapper already denies the Task tool;
the others have no Claude-subagent path anyway). Sub-orchestration is Fable's privilege, to spare its
tokens; a foreign model fanning out just multiplies cost and correlated error.

**Every dispatch prompt, whatever the lane:** tell the model to FAIL-FAST if kagi-ken (web search) or
its file-read tools are unavailable — do NOT fall back to reasoning from training data. Online research
is load-bearing here: for anything recent or cutting-edge these models' priors are stale and confidently
wrong, so absent research tooling the honest move is to abort and report the gap, not to guess.

When the dispatch is a red-team/crosscheck, the *framing* (disown-and-invert, bracket hard constraints
verbatim, guard against manufactured faults) is `/adversarial-crosscheck`'s job — build it per that
skill and route it through here. Not every dispatch is a crosscheck. (When characterized framing is
appropriate, Fable may need slightly more prompting than otherwise - but primarily to build the story
and establish the owned-position; still conversational, still very light on the *constraints* and
enumeration.)

When **Fable** runs a crosscheck/review specifically, mandate the ORDER of its first moves so its own
intelligence sets the frame before any lesser input can dilute it: (1) a deep read of the core
materials; (2) a **reasoning-only pass — no tools, no subagents** — laying out its own report structure
and initial judgement; and only THEN (3) fan out research subagents, code-editing/testing, or focused
sub-reviewers as warranted. Never let it consume a lower-reasoning agent's conception of the review
before its own is committed — that watering-down is the whole thing you're paying Fable to avoid.

## Two dispatch modes — decide before you prompt

The whole dispatch differs by mode:

- **Agentic worker (write-authorized, in a worktree).** For complex problems, or ANY task that edits
  files, compiles, or runs tests. Give the model its own worktree and write access, and instruct it to
  **commit as it goes and keep its own notes committed and up to date as it works** — the branch and
  its commit trail ARE the deliverable and the audit log. Parallel workers each get a SEPARATE worktree
  so they never collide. You review the branches.
- **Read-only review (no worktree, no write).** For a narrow-scoped critique that is neither large in
  scope NOR needs editing/compiling/tests. The model reads (or takes a self-contained packet) and
  reports; you adjudicate. No worktree, no edit authorization to the harness.

Default to read-only review for a bounded critique; escalate to agentic-worker the moment the task is
large or touches code/build/tests.

**Worker commit discipline (all agentic lanes).** The git tree is the product: the worker commits
GRANULARLY as it goes — one coherent commit per logical step, not one dump at the end — and puts its
final summary at the conductor-named DURABLE report path, kept OUT of commit messages. Every worker
follows the house commit convention (`~/.claude/skills/commit/SKILL.md` + any `.gitlabels`, tagging
AI-authored commits); the foreign shims append the commit skill to the model's prompt automatically
(a sandboxed model can't reach `~/.claude`), a native Fable reads it directly.

Two enablers make worker SELF-commit actually work — without them the model dumps *suggested* commits
into its final message and commits nothing (observed on both foreign lanes):
- **Autonomous-commit sentinel.** Harness worker branches are `worktree-agent-*`, NOT `ai/`-prefixed, so
  the commit skill defaults to message-only mode. The shim `touch`es a `.claude-commit` sentinel in the
  worktree to switch it into autonomous-commit mode (untracked scratch; never staged).
- **Writable gitdir (Windows Codex).** A linked worktree's real gitdir is at `<main>/.git/worktrees/<name>`,
  OUTSIDE the worktree — the Codex sandbox can't write its `index.lock` there and fails every commit. The
  shim ACL-grants the sandbox users write to the gitdir too, not just the worktree.
Shim-commits-on-the-worker's-behalf is the LAST-resort backstop, not the plan. `ds-write`'s restricted
mode still often declines to commit even so, so the deepseek-worker shim treats guaranteeing the commit
as its own job.

## The dispatch bundle — one file, one conductor-emission

Do NOT write a packet per model. Emit the WHOLE stable as ONE file in a SINGLE Write — a dispatch
bundle with each clearly-delimited, per-model-tuned section included serially — then STOP and let the
human review, tweak, and ack the bundle before any dispatch. Rationale: one conductor emission (no
tool-call churn), the human reviews and adjusts every prompt in the stable at once, and only then
are the lanes fanned out. A bundle carries at most ONE Fable section (its ack is covered by the human
acking the bundle).

Bundle format — one section per lane, fenced by markers a low-reasoning shim can grep exactly:
```
=== DISPATCH: sol | mode=worker | base=<target-sha> ===
<the Sol-tuned prompt: goal + real guardrails; commit-as-you-go instruction for worker mode>
=== END DISPATCH: sol ===

=== DISPATCH: deepseek | mode=review ===
<the DeepSeek-tuned prompt: narrow brief, explicitly enumerated do/don't constraints>
=== END DISPATCH: deepseek ===
```

Each Sonnet-tier shim is dispatched with `isolation: worktree` and handed the bundle PATH, its own KEY,
(worker mode) the conductor's target commit-SHA, and the two paths it must NOT operate in — the PROJECT
ROOT and the CONDUCTOR'S OWN worktree. It does EXACTLY, in order: (1) for a worker lane, CONFIRM
ISOLATION FIRST — assert `git rev-parse --show-toplevel` is a `.claude/worktrees/agent-*` path and is
neither of the two forbidden paths; abort if not (an un-isolated shim running a base-change against the
shared tree once reset the human's main checkout). Then base the worktree: if HEAD already equals <SHA>
do nothing, else `git switch -C <its-branch> <SHA>` — NEVER `git reset --hard` (the git-deny hook blocks
it, reserved for the human; a blocked reset also signals you may be in the wrong tree). Then AUTHORIZE —
`mise trust`, the Windows codex `icacls` grant on worktree AND gitdir, the `.claude-commit` sentinel
(the conductor states the desired end-state; the shim does the tool-calls); (2) extract the one section
between `=== DISPATCH: <key> …` and `=== END DISPATCH: <key> ===`, verbatim, to a tempfile (or stdin),
and ASSERT it is non-empty (its key matched) — abort if the section is missing rather than falling back
to another key/bundle/worktree; (3) dispatch via that model's call below, cwd = this worktree; (4) make
the output DURABLE and return a POINTER, not the payload — a worker lane already committed its work into
the branch; a packet/review lane writes the model's report to the conductor-named durable file and
commits it. The shim returns to the conductor ONLY the durable path (or branch), the exit status, and
any prepended setup errors — NEVER the report body. It never edits the prompt, touches another section,
or `git worktree add`s.

The shim's dispatch prompt (which the conductor writes) MUST also carry three guards:
- **A bounded debug budget.** State it explicitly: "at most FIVE failures may be debugged or
  re-attempted; then fail and return to your conductor for repair." A low-reasoning relay must never
  loop indefinitely on a broken lane.
- **Report errors UPWARD; never paper over them.** Even if a later retry succeeds, PREPEND the final
  report with every dispatch/setup error hit along the way. A silently-recovered failure hides a real
  fragility from the conductor.
- **Stay alive to collect the run — never background-and-exit.** The foreign call routinely outlives the
  ~10-min synchronous Bash-tool cap, so a foreground call dies at the cap (exit 143). The shim must
  BACKGROUND the invocation (detached, with a completion-marker file), then hold ITSELF alive with a
  CHUNKED foreground poll-waiter — a `while`/`for` loop that sleeps and checks the marker in sub-cap
  chunks, re-issued until the run finishes — and only THEN commit + return the pointer. It must NOT end
  its turn while the run is in flight (that orphans the run and forces a conductor resume — see below).

Shims exist ONLY to wrap the foreign harnesses' odd invocation forms and bug-profiles and to spend cheap
tokens on setup/debug instead of yours. Harness-NATIVE subagents (Fable, any `model:` Agent) need no
shim — dispatch them directly.

**Shim model rule (cost-critical).** The shims are relays — they run on a CHEAP model, never yours. The
agent defs pin `model: sonnet`; keep it. Any ad-hoc `Agent` dispatch must pass an explicit cheap
`model`; an unpinned subagent inherits the CONDUCTOR's model and bills every prompt and report at
frontier rates (this once burned a week of plan quota in minutes). Fable is the exception — it IS the
expensive model, dispatched with `model: fable` under human ack.

**Dispatch in background and in parallel.** These are slow, network-bound, independent calls. Fan the
shims out in the background (worker lanes each into their own worktree); a three-lane review costs about
one call's wall-time, not three. Collect, then adjudicate together.

**Never SendMessage-resume a backgrounded foreign shim.** If a shim returns without a pointer (it
background-exited its foreign call), do NOT resume it to "finish" — a resumed shim can have its branch
re-checked-out at the PROJECT ROOT, hijacking the shared main checkout and cross-contaminating lanes
(both observed). The stay-alive waiter-loop guard above is what prevents the background-exit in the first
place; if one slips through anyway, either rescue the lane's output READ-ONLY (inspect its worktree, and
if a valid report exists, cherry-pick/commit it yourself from a `.claude` worktree) or re-run the lane
CLEAN. Resume is the hijack-adjacent step; avoid it.

**Conductor pre-flight (per lane, before fan-out).** The bundle carries only prompt TEXT; the Agent()
call parameters are assembled separately at dispatch time, so a forgotten one is silent and unchecked.
Before firing each worker lane, confirm the call carries: `isolation: "worktree"` (its omission on four
lanes is what let shims reset the shared tree); a cheap pinned `model` (never inherit the conductor's);
the base commit-SHA; the durable output path; the extraction KEY; and the two forbidden paths (project
root + your own worktree) for the shim's self-check. Point the shim at ONE authoritative bundle path and
forbid sibling-worktree fallback — a shim that couldn't find its bundle once wandered to a stale sibling
worktree and reviewed the wrong copy. If the bundle won't exist at the base SHA (it's newer than the
review point), hand the shim an absolute path to a stable checkout that has it, not a path inside the
about-to-be-reset worktree.

## The dispatch calls (verbatim, with why each flag)

### Fable (Claude 5, in-lineage) — human-ack, at most one
Not a CLI, and NO shim (native invocation is safe): dispatch a native Agent subagent with `model:
fable`. Worker mode: give it an isolated worktree (`isolation: worktree`), full tools, and a short
goal-first prompt telling it to commit granularly as it goes (it has the `commit` skill — read it and
honor `.gitlabels`) and to put its final report at the durable path. Review mode: read-only, returns its
assessment. One per task; never parallel Fables.
- **Worktree-fork rule (same as every agentic subagent).** `isolation: worktree` forks from PROJECT
  ROOT, so put the target commit-SHA in Fable's prompt and have it base its fresh worktree there before
  working — if HEAD isn't already <SHA>, `git switch -C <its-branch> <SHA>` (NOT `git reset --hard`; the
  git-deny hook blocks it). It has full git, so it self-commits.

### Codex / GPT-5.6-Sol — review (read-only) and work (write)
Read-only review:
```sh
cd <git-repo-root-containing-artifacts> && \
  codex exec --json -o "$SCRATCH/codex-report.md" - < "$PROMPT_FILE"
```
Work (edits + self-reports; commits as it goes in worker mode):
```sh
cd <workspace-root> && \
  codex exec -s workspace-write -m gpt-5.6-sol -c 'model_reasoning_effort="high"' \
    --json -o "$SCRATCH/codex-final.md" - < "$PROMPT_FILE"
```
- `-m gpt-5.6-sol` pins the model; `-c 'model_reasoning_effort="high"'` pins reasoning (single-quote so
  the TOML string survives the shell). `-s workspace-write` grants writes (work mode only); read-only is
  the DEFAULT — for review pass no `-s`, never a `--dangerously-*` flag.
- CWD / read-scope RULE (native Windows): the read-only sandbox trusts only a cwd that is ITSELF a
  git-repo root; loose artifacts must be copied into a scratch `git init` repo (say so in the prompt).
- STDIN RULE: prompt via `- <` stdin, never argv (multi-line argv dies at the mise shim on Windows).
- `--json` = event stream on stdout; `-o` = clean final message to file. In work mode the deliverable is
  the commits/worktree, not the final message. Threaded follow-up: `codex exec resume --last "$MSG"`.
- In WORKER mode this call routinely outruns the ~10-min sync Bash cap: background it with a
  completion-marker and hold the shim alive with a chunked foreground poll-waiter — never run it
  synchronously, never background-and-exit (see the stay-alive guard and the codex-worker def).
- Native-Windows `workspace-write` has a setup wrinkle — see "Worktree & workspace topology".

### DeepSeek V4-Pro — agentic read (default) and write
Read-only review (default `ds-review`): nested Claude Code, model pinned `deepseek-v4-pro`, read-only
toolset (`Read,Grep,Glob` + kagi), reads scoped to the cwd subtree — so cd to the artifacts' ROOT:
```sh
cd <artifacts-root> && ds-review < "$PROMPT_FILE" > "$SCRATCH/deepseek-report.json"
```
Report is `.result` in the JSON envelope. Prompt on stdin (no ARG_MAX ceiling, no `$` re-expansion).
Uses `op` for the key — the human must approve the 1Password prompt, or export `DEEPSEEK_API_KEY`.

Write/worker lane (`ds-write` — same wrapper, `Write,Edit,Bash` allowed): lets DeepSeek edit files and
run git. Same isolation and cwd-subtree scoping; runs UNSANDBOXED as you (no separate sandbox user, and
Bash is real shell) — the worktree + branch are the containment, not an OS sandbox. It CAN self-commit,
but its restricted mode frequently DECLINES to (handing back a suggested commit instead), so the
deepseek-worker shim guarantees the commit itself rather than trusting the model.
```sh
cd <workspace-root> && ds-write < "$PROMPT_FILE" > "$SCRATCH/deepseek-final.json"
```
Still lower-intelligence, so verify its work more thoroughly; its cheapest, strongest use remains the
read/review lane. Reach for the worker lane when the task is genuinely agentic work, not a bounded critique.

### Antigravity (Gemini) — least-exercised; verify before relying
```sh
antigravity -p "$PROMPT" --print-timeout 300s </dev/null > "$SCRATCH/antigravity-report.txt"
```
Print mode: single-shot PLAIN TEXT, no tools, no JSON. The prompt MUST be fully self-contained.
`--print-timeout` takes a Go duration (`300s`). Not recently exercised here; confirm before trusting.

## Directory-trust tooling (worktree dispatch trips this)

Launching a foreign harness inside a fresh worktree hits directory-trust gates before the model runs.
Known: **mise** refuses to run (so the harness won't launch) from a worktree whose `.config/mise.toml`
isn't trusted; trusting it can fire side effects (e.g. a `uv` venv). Codex has its own workdir trust
(`[projects.'…'] trust_level`). Assume other tools may gate too.

Rule: **if the project root is already trusted, or the human instructs it, extending that trust to the
new worktree is reasonable without a fresh ack** (`mise trust <worktree>/.config/mise.toml`). Make the
decision yourself and *tell* the shim what you want; don't leave it up to the shim's reasoning. (The
shim can handle the tool-calls and debuging; tell it your desired end-state and authorizations.)

## Worktree & workspace topology (worker mode)

Every agentic (non-packet) subagent — foreign-shim or native — runs in a harness worktree via
`isolation: worktree`; nobody runs `git worktree add`. `isolation: worktree` is a caller-supplied Agent()
parameter AND pinned in the shim agent-defs' frontmatter — keep both (the frontmatter is the
load-bearing default; the def cannot self-verify it took, so the shim still self-checks). Because the
fork is from PROJECT ROOT, the conductor puts a target commit-SHA in every agentic dispatch prompt, and
the subagent bases its worktree there before anything else. Parallel workers are isolated automatically —
each gets its own worktree/branch. Conventions:

- **Isolation self-check, THEN base via `git switch` — never `git reset --hard`.** The shim first asserts
  it is in its OWN fork (`git rev-parse --show-toplevel` is a `.claude/worktrees/agent-*` path, and is
  neither the project root nor the conductor's worktree — the conductor names both) and ABORTS otherwise;
  only then, if HEAD isn't already the target SHA, `git switch -C <its-branch> <SHA>`. A bare
  `git reset --hard` is blocked by the git-deny hook (reserved for the human) — and a shim that skips the
  self-check and resets an un-isolated tree is exactly what once clobbered the human's main checkout.
- **Workers self-commit granularly; the shim only backstops.** The worker commits its own work as it
  goes, enabled by the `.claude-commit` sentinel + (Windows Codex) the gitdir ACL grant (see "Worker
  commit discipline"). The shim commits on the worker's behalf ONLY as a last resort when self-commit
  still failed — and prepends that failure to its return. `ds-write` restricted mode is the common
  last-resort case; native Fable always self-commits.
- **Native-Windows codex `workspace-write`** runs commands as separate sandbox users that need an ACL on
  the workspace; codex auto-grants it for most repos but not all. Do-every-time for codex-WRITE on
  Windows: fail-soft grant BOTH the worktree AND its linked gitdir before dispatch, IGNORE any error.
  The gitdir grant is what lets Codex self-commit — a linked worktree's gitdir is at
  `<main>/.git/worktrees/<name>`, outside the worktree, and without write there Codex hits
  `index.lock: Permission denied` on every commit. Pass Windows-style paths (NOT `$(pwd)`, whose POSIX
  form icacls can't parse):
  ```sh
  WT="$(cygpath -w "$(pwd)")"; GD="$(cygpath -w "$(git rev-parse --git-dir)")"
  MSYS_NO_PATHCONV=1 icacls "$WT" /grant "CodexSandboxOffline:(OI)(CI)(M)" /grant "CodexSandboxOnline:(OI)(CI)(M)"
  MSYS_NO_PATHCONV=1 icacls "$GD" /grant "CodexSandboxOffline:(OI)(CI)(M)" /grant "CodexSandboxOnline:(OI)(CI)(M)"
  ```
  It no-ops off-Windows and where the users don't exist, and fixes the common failure in place so the
  shim never loops on it. Still failing (`index.lock`/`CreateProcessWithLogonW`/`Access is denied`/
  wrote-nothing)? Read `windows-codex-leads.md` for the one-line fixes and WSL2 / `danger-full-access`
  alternatives, and hand debugging to a subagent — don't dig inline.

## Durable outputs, one batched adjudication

Detailed subagent results must NOT trickle into your context one at a time. Default to making every
lane's full output durable, and consume them all in ONE later pass.

- **Durable by default.** Every dispatch's full output ends as a committed file or branch, never only a
  scratch tempfile: worker lanes commit their work and notes into their branch; packet/review lanes have
  the shim write the report to a durable file and commit it. Shims return only pointers (path/branch +
  status), so nothing long enters your context until you choose to read it.
- **Where it lives** (unless the human directs otherwise): the project's house-style location if it has
  one; else `.claude/reports/<slug>/` for a standalone invocation; else the active `.claude/research/…`
  dir when running under /interactive-research. Save the prompt-kit (the whole bundle) there too — the
  kit plus every report stays durable together.
- **One batched adjudication, after everything completes.** Collect the branches (merge, cherry-pick, or
  just review — whatever fits the task) and read the committed reports together in a single pass, not
  lane-by-lane as they return.
- **The read may be rewound — the human's call.** Because the outputs are durable and self-describing,
  the reading/adjudication can happen in a FRESH, rewound context to save conductor tokens. If the human
  invoked this skill they'll likely rewind before adjudication — so leave the kit and reports on disk and
  do NOT summarize them into your context first. If YOU reached for the skill mid-task (to review some
  work independently), you can't self-rewind — adjudicate in-context once the lanes finish. Either way,
  nothing long lands in-context until that one batched read.

**Adjudicating (purity protocol).** You are the anchor: (1) trust the artifact/diff, not a worker's
narration — it can confabulate (Codex once claimed a section "was already present" that it had just
added); (2) NEVER quote raw foreign output wholesale to the human or paste it into a durable doc as-is —
it informs your assessment, it does not become it; (3) label provenance (model + lineage) on anything
that survives; (4) spend scrutiny on the UNVERIFIED bucket first — wrong findings cluster there.

## MCP parity (read-only web search on every lane)

Every lane carries **kagi-ken** (Kagi search + summarizer, read-only). Rule: **only read-only MCP
servers** on foreign lanes. Config is per-machine (INSTALL.md); the shared credential lives in one
canonical file, every entry secret-free. Codex and DeepSeek invoke it headless; Antigravity's headless
print mode does not, so treat that lane as search-less.

## Calibration (weight review findings by model character)

- **Precision: Fable > Codex/Sol > DeepSeek ≫ Antigravity** — tracks intelligence and cost. Fable is
  IN-lineage, so it adds power but NOT decorrelation; weight it as a strong reviewer, not an independent
  one. Weight a lone Antigravity flag lightest, a lone Codex/Sol flag heavily — but still verify.
- **Codex / GPT-5.x** over-flags severity; treat its "critical"s as "worth checking".
- **DeepSeek** is competent but lower-intelligence; a genuine cheap third angle, not a peer.
- **Agreement across foreign models is weak evidence** — shared training data gives correlated blind
  spots; convergence is a mild signal, not proof. Don't let unanimity end your own scrutiny.

## Failure modes

- **Auth** — Codex: `codex login`. DeepSeek: approve the `op` prompt (human-present) or export
  `DEEPSEEK_API_KEY`; a missed prompt yields "authorization timeout" / "Not logged in". Antigravity:
  re-run once interactively.
- **Quota** — Codex `Quota exceeded` = the funded OpenAI API account needs credit (billing, human-gated).
  Antigravity free tier ≈20 req/day. Fable: watch spend — it's an order of magnitude the priciest lane.
- **Native-Windows Codex read scoping** — reads trusted only from a git-repo-root cwd; denials elsewhere
  are expected. Last-resort read widening: `-c 'sandbox_permissions=["disk-full-read-access"]'`.
- **Native-Windows Codex WRITE failure** (`CreateProcessWithLogonW`/`Access is denied`/wrote-nothing) —
  the elevated sandbox's per-workspace ACL grant didn't fire; fix + paths-forward in
  `windows-codex-leads.md`. Apply it, don't debug inline.
