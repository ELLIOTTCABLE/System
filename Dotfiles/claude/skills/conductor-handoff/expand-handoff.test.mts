import assert from "node:assert/strict"
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { expand, HARNESSES } from "./expand-handoff.mts"

const dir = mkdtempSync(join(tmpdir(), "expand-handoff-"))
const numberedLines = (count: number) => Array.from({ length: count }, (_, i) => `line ${i + 1}`).join("\n") + "\n"
const short = join(dir, "short.md")
const long = join(dir, "long.md")
const other = join(dir, "other.md")
const huge = join(dir, "huge.md")
const agents = join(dir, "sub", "AGENTS.md")
const pickup = join(dir, "pickup.md")
writeFileSync(short, numberedLines(10))
writeFileSync(long, numberedLines(400))
writeFileSync(other, numberedLines(400))
writeFileSync(huge, numberedLines(3000))
mkdirSync(join(dir, "sub"))
writeFileSync(agents, numberedLines(3))

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

test("harness-loaded files and [no-inline] are never inlined; [inline] overrides the cost model", () => {
   const agentsCall = `Read(file_path="${agents}")`
   const shortCall = `Read(file_path="${short}")`
   const longCall = `Read(file_path="${long}", offset=1, limit=300)`
   const handoff = `${agentsCall}\n${shortCall} [no-inline]\n${longCall} [inline]\n`
   const { output, batch } = expand(handoff, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.equal(lines[3], "<result>")
   assert.equal(lines.filter((line) => line === "<result>").length, 1)
   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=2)`,
      agentsCall,
      shortCall,
      `Read(file_path="${pickup}", offset=3, limit=304)`,
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
   const conditional = `Read(file_path="${long}", offset=1, limit=300)`
   const mandatory = `Read(file_path="${short}", offset=1, limit=2)`
   const handoff = `${conditional}\n   [when] the human asks about X.\n${mandatory}\n   holds: the first two lines.\nAfter.\n`
   const { output, batch } = expand(handoff, { pickupPath: pickup })

   const lines = output.split("\n")
   assert.deepEqual(lines.slice(2, 5), [mandatory, "   holds: the first two lines.", "<result>"])
   assert.deepEqual(batch, [`Read(file_path="${pickup}", offset=1, limit=10)`])
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

test("reads split to stay under the harness's per-read cap are never merged past it", () => {
   const a = `Read(file_path="${huge}", offset=1, limit=1000)`
   const b = `Read(file_path="${huge}", offset=1001, limit=1200)`
   const { batch, merged } = expand(`${a}\n${b}\n`, { pickupPath: pickup })

   assert.equal(merged, 0)
   assert.deepEqual(batch.slice(1), [a, b])
})

test("a read too large for one read is flagged, since it would arrive truncated", () => {
   const { warnings } = expand(`Read(file_path="${huge}")\n`, { pickupPath: pickup })

   assert.equal(warnings.length, 1)
   assert.match(warnings[0], /^line 1: .*huge\.md lines 1-3000 may be more than one read returns/)
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
