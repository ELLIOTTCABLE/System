import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { dirname, join } from "node:path"
import { test } from "node:test"
import { fileURLToPath } from "node:url"
import { callingHarness, callingModel, expand, HARNESSES, inForm } from "./expand-handoff.mts"

const script = fileURLToPath(new URL("./expand-handoff.mts", import.meta.url))
// the CLI defaults to whichever harness runs the tests
const hermetic = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^(PI_|CLAUDE)/.test(key)))

const dir = mkdtempSync(join(tmpdir(), "expand-handoff-"))
const numberedLines = (count: number) => Array.from({ length: count }, (_, i) => `line ${i + 1}`).join("\n") + "\n"
const short = join(dir, "short.md")
const long = join(dir, "long.md")
const other = join(dir, "other.md")
const huge = join(dir, "huge.md")
const pickup = join(dir, "pickup.md")
writeFileSync(short, numberedLines(10))
writeFileSync(long, numberedLines(400))
writeFileSync(other, numberedLines(400))
writeFileSync(huge, numberedLines(3000))

// a throwaway project to launch the successor in, holding `files`
function project(files: Record<string, string>): string {
   const root = mkdtempSync(join(tmpdir(), "expand-handoff-project-"))
   for (const [path, text] of Object.entries(files)) {
      mkdirSync(dirname(join(root, path)), { recursive: true })
      writeFileSync(join(root, path), text)
   }
   return root
}

test("a short Claude Code read is inlined as the harness would return it", () => {
   const call = `Read(file_path="${short}", offset=2, limit=3)`
   const { output, batch, warnings } = expand(`Prose.\n${call}\nMore prose.\n`, { pickupPath: pickup })

   assert.equal(
      output,
      `Prose.\n${call}\n<result>\n<name>Read</name>\n<output>2\tline 2\n3\tline 3\n4\tline 4</output>\n</result>\nMore prose.\n`,
   )
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=9)`])
   assert.deepEqual(warnings, [])
})

test("a long read is left to the successor, and the batch keeps document order", () => {
   const longCall = `Read(file_path="${long}", offset=1, limit=300)`
   const handoff = `Intro.\n${longCall}\nBetween.\n- Read(file_path="${short}")\nOutro.\n`
   const { output, batch } = expand(handoff, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.equal(lines[1], longCall)
   assert.equal(lines[2], "Between.")
   assert.equal(lines[4], "<result>")
   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=2)`,
      longCall,
      `Read(file_path="${pickup}", offset=3, limit=16)`,
   ])
})

test("pi reads are inlined unnumbered, with pi's notice, and page reads mirror pi's syntax", () => {
   const call = `read(path="${short}", offset=2, limit=3)`
   const { output, batch } = expand(`${call}\n`, { pickupPath: pickup })

   assert.equal(
      output,
      `${call}\n<result>\n<name>read</name>\n<output>line 2\nline 3\nline 4\n\n` +
         `[7 more lines in file. Use offset=5 to continue.]</output>\n</result>\n`,
   )
   assert.deepEqual(batch, [`read(path="${pickup}", offset=1, limit=9)`])
})

test("pi inlines even a long read, since its pages carry no line numbers", () => {
   const { output } = expand(`read(path="${long}", offset=1, limit=300)\n`, { pickupPath: pickup })

   assert.match(output, /<output>line 1\n/)
})

test("[no-inline] keeps a read real, and [inline] overrides the cost model", () => {
   const shortCall = `Read(file_path="${short}")`
   const longCall = `Read(file_path="${long}", offset=1, limit=300)`
   const handoff = `${shortCall} [no-inline]\n${longCall} [inline]\n`
   const { output, batch } = expand(handoff, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.equal(lines[2], "<result>")
   assert.equal(lines.filter((line) => line === "<result>").length, 1)
   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=1)`,
      shortCall,
      `Read(file_path="${pickup}", offset=2, limit=304)`,
   ])
})

test("conditional reads are never batched, and are inlined only when likely and cheap", () => {
   const unlikely = `Read(file_path="${long}", offset=1, limit=300) [when] the human asks about X [p=0.05]`
   const likely = `Read(file_path="${short}", offset=1, limit=2) [p=0.9]`
   const { output, batch } = expand(`${unlikely}\n${likely}\n`, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.equal(lines[1], likely)
   assert.equal(lines[2], "<result>")
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=7)`])
})

test("a garbled [p=…] still marks a read conditional", () => {
   const { batch } = expand(`Read(file_path="${long}", offset=1, limit=300) [p=often]\n`, { pickupPath: pickup })

   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=1)`])
})

test("[inline] on a read too large to inline warns, and the read is issued instead", () => {
   const { batch, warnings } = expand(`Read(file_path="${huge}") [inline]\n`, { pickupPath: pickup })

   assert.equal(warnings.length, 1)
   assert.match(warnings[0], /^line 1: .*too large to inline; issued instead$/)
   assert.equal(batch.length, 3)
})

test("a CRLF handoff stays CRLF, inlined results included", () => {
   const call = `Read(file_path="${short}", offset=1, limit=1)`
   const { output } = expand(`Intro.\r\n${call}\r\n`, { pickupPath: pickup })

   assert.equal(output, `Intro.\r\n${call}\r\n<result>\r\n<name>Read</name>\r\n<output>1\tline 1</output>\r\n</result>\r\n`)
})

test("an unlikely conditional read stays un-inlined even where inlining is cheap, to spare the context window", () => {
   const call = `read(path="${short}") [when] the human asks about X`
   const { output } = expand(`${call}\n`, { pickupPath: pickup })

   assert.equal(output, `${call}\n`)
})

test("prose that merely mentions a condition never makes a read conditional", () => {
   const call = `Read(file_path="${long}", offset=1, limit=300)`
   const { batch } = expand(`${call}\n   holds: what applies when: the flag is set; p=0.1 of cases\n`, {
      pickupPath: pickup,
   })

   assert.ok(batch.includes(call))
})

test("indented lines below a read annotate it, and its inlined result follows them", () => {
   const call = `Read(file_path="${short}", offset=1, limit=2)`
   const handoff = `${call}\n   holds: the first two lines.\nAfter.\n`
   const { output, batch } = expand(handoff, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.deepEqual(lines.slice(0, 3), [call, "   holds: the first two lines.", "<result>"])
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=8)`])
})

test("short text between issued reads shares a page with them; long prose gets its own", () => {
   const a = `Read(file_path="${long}", offset=1, limit=100)`
   const b = `Read(file_path="${other}", offset=101, limit=100)`
   const c = `Read(file_path="${long}", offset=201, limit=100)`
   const prose = "word ".repeat(400).trim()
   const { batch } = expand(`${a}\n-- a short label --\n${b}\n${prose}\n${c}\n`, { pickupPath: pickup })

   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=3)`,
      a,
      b,
      `Read(file_path="${pickup}", offset=4, limit=2)`,
      c,
   ])
})

test("nearby reads of one file become one issued read when that's cheaper, the handoff untouched", () => {
   const a = `Read(file_path="${long}", offset=1, limit=30)`
   const b = `Read(file_path="${long}", offset=34, limit=30)`
   const handoff = `${a}\n-- a short label --\n${b}\n`
   const { output, batch, merged } = expand(handoff, { pickupPath: pickup, horizon: 40 })

   assert.equal(output, handoff)
   assert.equal(merged, 2)
   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=3)`,
      `Read(file_path="${long}", offset=1, limit=63)`,
   ])
})

test("an unbounded read of a large file becomes reads that each fit, in its own call style", () => {
   const { batch, warnings, split } = expand(`Read(file_path="${huge}")\n`, { pickupPath: pickup })

   assert.deepEqual(warnings, [])
   assert.equal(split, 1)
   assert.deepEqual(batch.slice(1), [
      `Read(file_path="${huge}", offset=1, limit=2000)`,
      `Read(file_path="${huge}", offset=2001, limit=1000)`,
   ])
})

test("a run of hand-split reads is re-cut into as few reads as the harness allows", () => {
   const reads = [
      [1, 500],
      [501, 500],
      [1001, 500],
      [1501, 1000],
   ].map(([offset, limit]) => `Read(file_path="${huge}", offset=${offset}, limit=${limit})`)
   const { batch } = expand(reads.join("\n") + "\n", { pickupPath: pickup })

   const spans = batch.slice(1).map((call) => {
      const [, offset, limit] = /offset=(\d+), limit=(\d+)/.exec(call)!
      return [+offset, +offset + +limit - 1]
   })
   assert.equal(spans.length, 2)
   assert.equal(spans[0][0], 1)
   assert.equal(spans[1][0], spans[0][1] + 1)
   assert.equal(spans[1][1], 2500)
   assert.ok(spans.every(([first, last]) => last - first + 1 <= 2000))
})

test("a read already covered by an earlier one is neither inlined nor batched again", () => {
   const first = `Read(file_path="${long}", offset=1, limit=300)`
   const again = `Read(file_path="${long}", offset=40, limit=10)`
   const prose = "word ".repeat(400).trim()
   const { output, batch, dropped } = expand(`${first}\n${prose}\n${again}\n`, { pickupPath: pickup })

   assert.equal(output, `${first}\n${prose}\n${again}\n`)
   assert.equal(dropped, 1)
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=1)`, first, `Read(file_path="${pickup}", offset=2, limit=2)`])
})

test("broken reads are reported against their handoff line and otherwise left alone", () => {
   const garbled = `Read(file_path="${short}", offset=two)`
   const missing = `Read(file_path="${join(dir, "gone.md")}")`
   const { output, batch, warnings } = expand(`${garbled}\n${missing}\n`, { pickupPath: pickup })

   assert.equal(output, `${garbled}\n${missing}\n`)
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=2)`, missing])
   assert.equal(warnings.length, 2)
   assert.match(warnings[0], /^line 1 looks like a read/)
   assert.match(warnings[1], /^line 2: can't find/)
})

test("JSON, positional, backticked and escaped-backslash calls all parse", () => {
   const json = `Read({"file_path": ${JSON.stringify(short)}, "offset": 2, "limit": 1})`
   const positional = `1. \`Read(${short})\``
   const { output, batch, warnings } = expand(`${json}\n${positional}\n`, { pickupPath: pickup })

   assert.deepEqual(warnings, [])
   assert.equal(output.split("\n").filter((line) => line === "<result>").length, 2)
   assert.equal(batch[0], `Read({"file_path": ${JSON.stringify(pickup)}, "offset": 1, "limit": 19})`)
})

test("expanding an already-expanded pickup changes nothing", () => {
   const handoff = `Intro.\nRead(file_path="${short}", offset=1, limit=3)\nRead(file_path="${long}")\n`
   const once = expand(handoff, { pickupPath: pickup })
   const twice = expand(once.output, { pickupPath: pickup })

   assert.equal(twice.output, once.output)
   assert.deepEqual(twice.batch, once.batch)
})

test("pages stay within budget and never split a call from its inlined result", () => {
   const tiny = { ...HARNESSES.claude, readBudget: 400 }
   const prose = Array.from({ length: 12 }, (_, i) => `Some prose, paragraph ${i + 1}.`)
   const reads = Array.from({ length: 4 }, (_, i) => `Read(file_path="${short}", offset=${i + 1}, limit=2)`)
   const handoff = [...prose.slice(0, 4), reads[0], ...prose.slice(4, 8), reads[1], reads[2], ...prose.slice(8), reads[3]]
   const { output, batch, inlined } = expand(handoff.join("\n") + "\n", { pickupPath: pickup, harness: tiny })

   const lines = output.split("\n")
   const forbiddenEnds = new Set<number>()
   lines.forEach((line, i) => {
      if (line !== "<result>") return
      for (let k = i - 1; lines[k] !== "</result>"; k++) forbiddenEnds.add(k + 1)
   })
   const pages = batch.map((call) => /offset=(\d+), limit=(\d+)/.exec(call)!).map(([, o, l]) => [+o, +o + +l - 1])
   assert.equal(inlined, 4)
   assert.ok(pages.length > 2)
   assert.equal(pages[0][0], 1)
   for (const [index, [first, last]] of pages.entries()) {
      if (index > 0) assert.equal(first, pages[index - 1][1] + 1)
      assert.ok(!forbiddenEnds.has(last), `page ${index + 1} ends inside an inlined result, at line ${last}`)
      const size = lines.slice(first - 1, last).reduce((sum, line) => sum + line.length + 8, 0)
      assert.ok(size <= tiny.readBudget, `page ${index + 1} is ${size} over a ${tiny.readBudget} budget`)
   }
   assert.equal(pages.at(-1)![1], lines.length - 1)
})

test("the CLI writes the pickup itself, the batch to stdout, and diagnostics to stderr", () => {
   const cliHandoff = join(dir, "cli-handoff.md")
   const cliPickup = join(dir, "cli-pickup.md")
   const longCall = `Read(file_path="${long}", offset=1, limit=300)`
   const handoff = `Intro.\n${longCall}\n`
   writeFileSync(cliHandoff, handoff)
   const run = spawnSync(process.execPath, [script, "--in", cliHandoff, "--out", cliPickup], { encoding: "utf8", env: hermetic })

   assert.equal(run.status, 0, run.stderr)
   assert.equal(readFileSync(cliHandoff, "utf8"), handoff)
   assert.equal(readFileSync(cliPickup, "utf8"), handoff)
   assert.deepEqual(run.stdout.trimEnd().split("\n"), [
      "Read all these in a single turn:",
      `Read(file_path="${cliPickup}", offset=1, limit=2)`,
      longCall,
   ])
   assert.match(run.stderr, /^expand-handoff: inlined 0 of 1 reads; 1 page\(s\)/)
})

test("the CLI refuses to overwrite the handoff it is reading", () => {
   const handoffPath = join(dir, "handoff.md")
   writeFileSync(handoffPath, "Intro.\n")
   const run = spawnSync(process.execPath, [script, "--in", handoffPath, "--out", handoffPath], { encoding: "utf8", env: hermetic })

   assert.equal(run.status, 2)
   assert.match(run.stderr, /is the handoff itself/)
   assert.equal(readFileSync(handoffPath, "utf8"), "Intro.\n")
})

test("the CLI takes no positional arguments and no stdin, only both --in and --out", () => {
   const handoffPath = join(dir, "flags-handoff.md")
   const pickupPath = join(dir, "flags-pickup.md")
   writeFileSync(handoffPath, "Intro.\n")
   const positional = spawnSync(process.execPath, [script, pickupPath], { input: "Intro.\n", encoding: "utf8", env: hermetic })
   const inOnly = spawnSync(process.execPath, [script, "--in", handoffPath], { encoding: "utf8", env: hermetic })
   const outOnly = spawnSync(process.execPath, [script, "--out", pickupPath], { input: "Intro.\n", encoding: "utf8", env: hermetic })

   assert.equal(positional.status, 2)
   assert.match(positional.stderr, /positional/)
   assert.equal(inOnly.status, 2)
   assert.equal(outOnly.status, 2)
   assert.match(outOnly.stderr, /give both --in <handoff-path> and --out <pickup-path>/)
   assert.equal(existsSync(pickupPath), false)
})

test("the calling model comes from pi's env, else the newest real model in Claude Code's transcript", () => {
   const config = join(dir, "claude-config")
   mkdirSync(join(config, "projects", "some-project"), { recursive: true })
   const entries = [
      { type: "assistant", message: { model: "claude-older" } },
      { type: "user", message: { content: "hi" } },
      { type: "assistant", message: { model: "claude-newer" } },
      { type: "assistant", message: { model: "<synthetic>" } },
   ]
   writeFileSync(join(config, "projects", "some-project", "abc.jsonl"), entries.map((e) => JSON.stringify(e)).join("\n") + "\n")

   assert.equal(callingModel({ CLAUDE_CONFIG_DIR: config, CLAUDE_CODE_SESSION_ID: "abc" }), "claude-newer")
   assert.equal(callingModel({ PI_MODEL: "pi-model", CLAUDE_CONFIG_DIR: config, CLAUDE_CODE_SESSION_ID: "abc" }), "pi-model")
   assert.equal(callingModel({}), undefined)
   assert.equal(callingHarness({ PI_SESSION_ID: "x", CLAUDECODE: "1" }), "pi")
   assert.equal(callingHarness({ CLAUDECODE: "1" }), "claude")
   assert.equal(callingHarness({}), undefined)
})

test("paths already in the asked-for form, and relative paths, are never translated", () => {
   assert.equal(inForm("C:\\Users\\ec\\a.md", "windows"), "C:\\Users\\ec\\a.md")
   assert.equal(inForm("\\\\wsl.localhost\\Ubuntu\\home\\ec\\a.md", "windows"), "\\\\wsl.localhost\\Ubuntu\\home\\ec\\a.md")
   assert.equal(inForm("/home/ec/a.md", "posix"), "/home/ec/a.md")
   assert.equal(inForm("notes/a.md", "windows"), "notes/a.md")
   assert.equal(inForm("notes/a.md", "posix"), "notes/a.md")
})

const noWsl = inForm("C:\\x", "posix") === "C:\\x" && "no wslpath reachable here"

test("paths cross between the Windows and WSL views of a file, there and back", { skip: noWsl }, () => {
   const drive = inForm("C:\\Users\\ec\\a.md", "posix")
   const native = inForm("/home/ec/a.md", "windows")

   assert.match(drive, /^\/.*\/Users\/ec\/a\.md$/)
   assert.match(native, /^\\\\wsl(\.localhost|\$)\\[^\\]+\\home\\ec\\a\.md$/)
   assert.equal(inForm(drive, "windows"), "C:\\Users\\ec\\a.md")
   assert.equal(inForm(native, "posix"), "/home/ec/a.md")
})

test("the CLI takes --in and --out in the other side's path form", { skip: noWsl }, () => {
   const otherSide = process.platform === "win32" ? "posix" : "windows"
   const handoffPath = join(dir, "cross-handoff.md")
   const pickupPath = join(dir, "cross-pickup.md")
   writeFileSync(handoffPath, "Intro.\n")
   const args = [script, "--in", inForm(handoffPath, otherSide), "--out", inForm(pickupPath, otherSide)]
   const run = spawnSync(process.execPath, args, { encoding: "utf8", env: hermetic })

   assert.equal(run.status, 0, run.stderr)
   assert.equal(readFileSync(pickupPath, "utf8"), "Intro.\n")
   assert.equal(run.stdout.trimEnd().split("\n")[1], `Read(file_path="${pickupPath}", offset=1, limit=1)`)
})

test("batched reads are printed in the harness's path form, whichever form the handoff used", { skip: noWsl }, () => {
   const kwargs = `Read(file_path="C:\\nowhere\\a.md", offset=1, limit=5)`
   const json = `Read({"file_path": "C:\\\\nowhere\\\\b.md"})`
   const { batch } = expand(`${kwargs}\n${json}\n`, { pickupPath: pickup, paths: "posix" })

   assert.match(batch[0], /^Read\(file_path="\/.*pickup\.md", offset=1, limit=2\)$/)
   assert.deepEqual(batch.slice(1), [
      `Read(file_path="${inForm("C:\\nowhere\\a.md", "posix")}", offset=1, limit=5)`,
      `Read({"file_path": "${inForm("C:\\nowhere\\b.md", "posix")}"})`,
   ])
})

test("a read of an instruction file the harness loaded at launch is skipped", () => {
   const root = project({ "CLAUDE.md": "@AGENTS.md\n", "AGENTS.md": numberedLines(10) })
   const call = `Read(file_path="${join(root, "AGENTS.md")}")`
   const { output, batch, loadedAtLaunch } = expand(`Prose.\n${call}\n`, { pickupPath: pickup, cwd: root })

   assert.equal(output, `Prose.\n${call}\n`)
   assert.equal(loadedAtLaunch, 1)
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=2)`])
})

test("a read stays real where inlining it would skip its directory's instruction files", () => {
   const root = project({ "sub/CLAUDE.md": "@NOTES.md\n", "sub/NOTES.md": "notes\n", "sub/a.md": "a\n" })
   const call = `Read(file_path="${join(root, "sub", "a.md")}")`
   const { output, batch, keptForSteering } = expand(`${call}\n`, { pickupPath: pickup, cwd: root })

   assert.equal(output, `${call}\n`)
   assert.equal(keptForSteering, 1)
   assert.deepEqual(batch.slice(1), [call])
})

test("a read is still inlined when another real read already loads its directory's instruction files", () => {
   const root = project({ "sub/CLAUDE.md": "rules\n", "sub/a.md": "a\n", "sub/big.md": numberedLines(300) })
   const small = `Read(file_path="${join(root, "sub", "a.md")}")`
   const big = `Read(file_path="${join(root, "sub", "big.md")}")`
   const { output, keptForSteering } = expand(`${big}\n${small}\n`, { pickupPath: pickup, cwd: root })

   assert.equal(keptForSteering, 0)
   assert.equal(output.split("\n")[2], "<result>")
})

test("a range on an instruction file is dropped, since the harness loads it whole", () => {
   const root = project({ "part/CLAUDE.md": numberedLines(30) })
   const file = join(root, "part", "CLAUDE.md")
   const partial = `Read(file_path="${file}", offset=1, limit=5)`
   const { output, batch, widened } = expand(`${partial}\n`, { pickupPath: pickup, cwd: root })

   assert.equal(widened, 1)
   assert.equal(output, `${partial}\n`)
   assert.deepEqual(batch.slice(1), [`Read(file_path="${file}", offset=1, limit=30)`])
})

test("a [when] read of an instruction file with a range is left as written, with a warning", () => {
   const root = project({ "part/CLAUDE.md": numberedLines(30) })
   const partial = `Read(file_path="${join(root, "part", "CLAUDE.md")}", offset=1, limit=5) [when] asked about parts`
   const { output, batch, warnings } = expand(`${partial}\n`, { pickupPath: pickup, cwd: root })

   assert.equal(output, `${partial}\n`)
   assert.equal(batch.length, 1)
   assert.equal(warnings.length, 1)
   assert.match(warnings[0], /^line 1: .*instruction file.*read the whole file$/)
})

test("pi, which loads nothing on reads, inlines what Claude Code keeps real", () => {
   const root = project({ "sub/AGENTS.md": "rules\n", "sub/a.md": "a\n" })
   const call = `read(path="${join(root, "sub", "a.md")}")`
   const { output, keptForSteering } = expand(`${call}\n`, { pickupPath: pickup, cwd: root, harness: "pi" })

   assert.equal(keptForSteering, 0)
   assert.equal(output.split("\n")[1], "<result>")
})
