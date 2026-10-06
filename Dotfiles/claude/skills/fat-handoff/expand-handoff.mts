#!/usr/bin/env node
import { execFileSync } from "node:child_process"
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join, resolve } from "node:path"
import { parseArgs } from "node:util"
import { fileKey, STEERING, type SteeringModel, type SteeringProfile, steeringModel } from "./steering.mts"

// per token, relative to uncached input; `--model` reads real ones from pi's store
const DEFAULT_PRICE = { output: 5, cacheRead: 0.1, cacheWrite5m: 1.25 }
// 1h cache writes bill 2x input, 5m ones 1.25x; pi's store lists 5m
const ONE_HOUR_WRITE_FACTOR = 2 / 1.25
const DEFAULT_HORIZON_REQUESTS = 150
const DEFAULT_CONDITIONAL_LIKELIHOOD = 0.3
const CHARS_PER_TOKEN = 4
// tool-use id and block, plus result wrapper, beyond the call's visible text
const CALL_FRAMING_TOKENS = 25
const READ_TOOL_NAMES = ["Read", "read"]
const PATH_KEYS = ["file_path", "path", "filePath", "file"]

type CallStyle = { kind: "kwargs" | "json" | "positional"; name: string; pathKey: string; quote: string }

export type Harness = {
   defaultStyle: CallStyle
   numbered: boolean // `N<TAB>line`, so reading a page numbers its inlined lines a second time
   lineNumberChars: number
   lineNumberTokens: number
   readBudget: number
   readUnit: "chars" | "bytes"
   readMaxLines: number
   cacheTtl: "5m" | "1h"
   moreLinesNotice: boolean
   steering: SteeringProfile
}

export const HARNESSES: Record<string, Harness> = {
   claude: {
      defaultStyle: { kind: "kwargs", name: "Read", pathKey: "file_path", quote: '"' },
      numbered: true,
      lineNumberChars: 7,
      lineNumberTokens: 2,
      readBudget: 60_000, // Read refuses results over 25k tokens; chars only track that loosely
      readUnit: "chars",
      readMaxLines: 2000,
      cacheTtl: "1h",
      moreLinesNotice: false,
      steering: STEERING.claude,
   },
   pi: {
      defaultStyle: { kind: "kwargs", name: "read", pathKey: "path", quote: '"' },
      numbered: false,
      lineNumberChars: 0,
      lineNumberTokens: 0,
      readBudget: 48_000, // pi truncates reads at 50KB
      readUnit: "bytes",
      readMaxLines: 2000,
      cacheTtl: "5m",
      moreLinesNotice: true,
      steering: STEERING.pi,
   },
}

const USAGE = `Usage: node expand-handoff.mts --in <handoff-path> --out <pickup-path> [options]

Copies the handoff at <handoff-path> into a pickup document at <pickup-path>. Where the handoff
dictates a read, the read's result is inlined after it if carrying the result pre-read costs the
successor less than issuing the read. Nothing else in the handoff changes. Stdout gets the one
batch of reads that delivers the whole document in order: its pages, interleaved with the reads
left un-inlined. Stderr gets any warnings and a summary.

  --in <handoff-path>  the handoff to expand; it is only read
  --out <pickup-path>  where to write the pickup document; the page reads point at it
  --harness claude|pi  the harness that will read the pickup (default: the one running this,
                       else guessed from the reads)
  --model <id>         price ratios for this model, from pi's model store (default: the model
                       running this, from PI_MODEL or the Claude Code session's transcript)
  --horizon <n>        requests the successor makes after standing up (default ${DEFAULT_HORIZON_REQUESTS})
  --cache-ttl 5m|1h    the successor's prompt-cache lifetime (default: 1h for claude, 5m for pi)
  --paths windows|posix
                       the path form the harness reads; set it when this runs on the other side
                       of Windows/WSL from the harness (default: the form of the side running this)

Paths in either form are accepted anywhere, translated by WSL's wslpath: C:\\x and
\\\\wsl.localhost\\<distro>\\x on the Windows side are /mnt/c/x and /x on the WSL side.

A read is a line that holds one read call, optionally bulleted or in backticks:
  Read(file_path="C:\\notes\\a.md", offset=10, limit=20)
  read(path="/notes/a.md")
  Read(notes/a.md)
  Read({"file_path": "C:\\\\notes\\\\a.md", "offset": 10})
Its annotation is the rest of that line plus any indented lines directly below it. An inlined
result goes after the annotation, which stays as written. Tags count only on the call's own line,
after the call; anywhere else they are prose, and the read stays mandatory:
  [when] <trigger>  a conditional read, issued only if the trigger fires, so never batched;
                    only this tag (or [p=…]) makes a read conditional, never prose like "when:"
  [p=0.2]           the chance a conditional read's trigger fires (default ${DEFAULT_CONDITIONAL_LIKELIHOOD})
  [inline]          inline even where the cost model says not to
  [no-inline]       never inline

Instruction files (CLAUDE.md, AGENTS.md, rules, and what they import) are treated as the harness
loads them: a read of one it loaded at launch is skipped; one is never inlined; a range on one is
dropped, as the harness loads it whole and a partial read would stop that (a [when] read is left as
written, with a warning); and a read is kept real where inlining it would skip instruction files the
harness loads for that file's directory.
`

type ReadCall = {
   line: number
   annotationEnd: number
   text: string
   style: CallStyle
   path: string
   offset?: number
   limit?: number
   conditional: boolean
   likelihood: number
   force?: "inline" | "no-inline"
}

const CALL_START = /^(\s*(?:[-*+]\s+|\d+[.)]\s+)?`*)([A-Za-z_]\w*)\s*\(/

function readCallStart(line: string): RegExpExecArray | undefined {
   const start = CALL_START.exec(line)
   return start && READ_TOOL_NAMES.includes(start[2]) ? start : undefined
}

function isAnnotation(line: string | undefined): boolean {
   return line !== undefined && /^\s+\S/.test(line) && !readCallStart(line)
}

// what may sit between two reads without landing before the first one's result: other reads' own
// lines and blank lines; any other text must follow that result
function readsOnly(gap: string[]): boolean {
   let annotating = false
   for (const line of gap) {
      if (readCallStart(line)) annotating = true
      else if (line.trim() === "") annotating = false
      else if (!(annotating && isAnnotation(line))) return false
   }
   return true
}

function parseCall(lines: string[], index: number): ReadCall | "malformed" | undefined {
   const line = lines[index]
   const start = readCallStart(line)
   if (!start) return undefined
   const open = start[0].length - 1
   const close = closingParen(line, open)
   const args = close < 0 ? undefined : parseArguments(line.slice(open + 1, close).trim())
   if (!args) return "malformed"

   let annotationEnd = index
   while (isAnnotation(lines[annotationEnd + 1])) annotationEnd++

   // only explicit tags, only on the call's own line: a mandatory read mistaken for conditional leaves the
   // successor reasoning from a partial foundation, which is far worse than an unneeded read
   const tags = line.slice(close + 1)
   const likelihoodTag = /\[p\s*=\s*([^\]]*)\]/i.exec(tags)
   const conditional = likelihoodTag !== null || /\[when\]/i.test(tags)
   let likelihood = 1
   if (conditional) {
      const tagged = Number(likelihoodTag?.[1])
      likelihood = tagged >= 0 && tagged <= 1 ? tagged : DEFAULT_CONDITIONAL_LIKELIHOOD
   }
   let force: ReadCall["force"]
   if (/\[no-inline\]/i.test(tags)) force = "no-inline"
   else if (/\[inline\]/i.test(tags)) force = "inline"

   return {
      line: index,
      annotationEnd,
      text: line.slice(start[1].length, close + 1),
      style: { ...args.style, name: start[2] },
      path: args.path,
      offset: args.offset,
      limit: args.limit,
      conditional,
      likelihood,
      force,
   }
}

function closingParen(s: string, open: number): number {
   let depth = 0
   let quote = ""
   for (let i = open; i < s.length; i++) {
      const c = s[i]
      if (quote) {
         if (c === quote) quote = ""
      } else if (c === '"' || c === "'") quote = c
      else if (c === "(") depth++
      else if (c === ")" && --depth === 0) return i
   }
   return -1
}

type Arguments = { style: Omit<CallStyle, "name">; path: string; offset?: number; limit?: number }
type Pair = { key: string; value: string; quote: string }

// values stay raw, never JSON-unescaped: models write bare-backslash Windows paths even in JSON,
// where `\n` in `C:\notes` would become a newline
const KWARG = /(\w+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^,\s]+))/g
const JSON_MEMBER = /["'](\w+)["']\s*:\s*(?:"([^"]*)"|'([^']*)'|([^,\s}]+))/g

function parseArguments(args: string): Arguments | undefined {
   if (args.startsWith("{")) return fromPairs("json", pairs(args, JSON_MEMBER))
   if (args.includes("=")) return fromPairs("kwargs", pairs(args, KWARG))
   const positional = /^(["']?)([^"',]+)\1$/.exec(args)
   if (!positional) return undefined
   return { style: { kind: "positional", pathKey: "", quote: positional[1] }, path: positional[2].trim() }
}

function pairs(args: string, pattern: RegExp): Pair[] {
   return [...args.matchAll(pattern)].map(([, key, double, single, bare]) => ({
      key,
      value: double ?? single ?? bare,
      quote: double !== undefined ? '"' : single !== undefined ? "'" : "",
   }))
}

function fromPairs(kind: "kwargs" | "json", found: Pair[]): Arguments | undefined {
   const byKey = new Map(found.map((pair) => [pair.key, pair]))
   const pathKey = PATH_KEYS.find((key) => byKey.has(key))
   const offset = byKey.get("offset")?.value
   const limit = byKey.get("limit")?.value
   if (!pathKey || !isLineCount(offset) || !isLineCount(limit)) return undefined
   const path = byKey.get(pathKey)!
   return {
      style: { kind, pathKey, quote: path.quote },
      path: path.value,
      offset: offset === undefined ? undefined : Number(offset),
      limit: limit === undefined ? undefined : Number(limit),
   }
}

function isLineCount(value: string | undefined): boolean {
   return value === undefined || /^\d+$/.test(value)
}

export type PathForm = "windows" | "posix"

function localForm(): PathForm {
   return process.platform === "win32" ? "windows" : "posix"
}

function formOf(path: string): PathForm | undefined {
   if (/^[A-Za-z]:[\\/]|^\\\\/.test(path)) return "windows"
   if (path.startsWith("/")) return "posix"
   return undefined
}

const converted = new Map<string, string>()

// the same file as the other side of Windows/WSL sees it; unchanged where there's no WSL to ask
export function inForm(path: string, form: PathForm): string {
   if (formOf(path) === undefined || formOf(path) === form) return path
   const key = `${form} ${path}`
   if (!converted.has(key)) converted.set(key, wslpath(path, form) ?? path)
   return converted.get(key)!
}

// WSL's own translator knows the drive mount root and this distro's share name
function wslpath(path: string, form: PathForm): string | undefined {
   const args = [form === "windows" ? "-w" : "-u", path]
   const [command, commandArgs] =
      process.platform === "win32" ? ["wsl.exe", ["-e", "wslpath", ...args]] : ["wslpath", args]
   try {
      const output = execFileSync(command, commandArgs, { encoding: "utf8", timeout: 10_000, stdio: "pipe" })
      return output.trim() || undefined
   } catch {
      return undefined
   }
}

// JSON-style calls keep their escapes in `path`
function writtenPath(call: ReadCall): string {
   return call.style.kind === "json" ? call.path.replace(/\\\\/g, "\\") : call.path
}

function harnessCall(call: ReadCall, form: PathForm): string {
   const written = writtenPath(call)
   const converted = inForm(written, form)
   if (converted === written) return call.text
   const replacement = call.style.kind === "json" ? JSON.stringify(converted).slice(1, -1) : converted
   return call.text.replace(call.path, () => replacement)
}

function locate(path: string): string | undefined {
   const spellings = [path, path.replace(/\\\\/g, "\\")]
   const candidates = spellings.flatMap((spelling) => [spelling, inForm(spelling, localForm())])
   if (/^~[\\/]/.test(path)) candidates.push(join(homedir(), path.slice(2)))
   return candidates.map((c) => resolve(c)).find((c) => existsSync(c) && statSync(c).isFile())
}

type Selection = { lines: string[]; start: number; end: number; total: number; limited: boolean }

function select(file: string, offset: number | undefined, limit: number | undefined): Selection | string {
   const text = readFileSync(file, "utf8")
   if (text.includes("\0")) return "it looks binary"
   // pi's count: a final newline adds an empty line
   const all = text.split("\n").map((line) => line.replace(/\r$/, ""))
   const last = all.at(-1) === "" ? all.length - 1 : all.length
   const start = Math.max(1, offset ?? 1)
   if (start > Math.max(last, 1)) return `offset ${start} is past its end (${last} lines)`
   const end = limit === undefined ? last : Math.min(all.length, start + limit - 1)
   return { lines: all.slice(start - 1, end), start, end, total: all.length, limited: limit !== undefined }
}

function renderBody(selection: Selection, harness: Harness): string[] {
   const { lines, start, end, total, limited } = selection
   const body = harness.numbered ? lines.map((line, i) => `${start + i}\t${line}`) : [...lines]
   if (harness.moreLinesNotice && limited && end < total)
      body.push("", `[${total - end} more lines in file. Use offset=${end + 1} to continue.]`)
   return body
}

function wrap(name: string, body: string[]): string[] {
   const glued = body.length > 0 ? [...body] : [""]
   glued[0] = `<output>${glued[0]}`
   glued[glued.length - 1] += "</output>"
   return ["<result>", `<name>${name}</name>`, ...glued, "</result>"]
}

function lineCost(line: string, harness: Harness): number {
   const size = harness.readUnit === "bytes" ? Buffer.byteLength(line) : line.length
   return size + 1 + harness.lineNumberChars
}

function sizeOf(lines: string[], harness: Harness): number {
   return lines.reduce((sum, line) => sum + lineCost(line, harness), 0)
}

function tokens(text: string): number {
   return Math.ceil(text.length / CHARS_PER_TOKEN)
}

type Target = {
   call: ReadCall
   file?: string
   selection?: Selection
   expanded: boolean
   loadedAtLaunch: boolean
   widened: boolean
}

function resolveTarget(call: ReadCall, lines: string[], warnings: string[]): Target {
   const expanded = lines[call.annotationEnd + 1]?.trim() === "<result>"
   const file = locate(call.path)
   if (!file) {
      warnings.push(`line ${call.line + 1}: can't find ${call.path}; left for the successor to read as written`)
      return { call, expanded, loadedAtLaunch: false, widened: false }
   }
   const selection = select(file, call.offset, call.limit)
   if (typeof selection === "string") {
      warnings.push(`line ${call.line + 1}: ${call.path}: ${selection}; left as written`)
      return { call, expanded, loadedAtLaunch: false, widened: false }
   }
   return { call, file, selection, expanded, loadedAtLaunch: false, widened: false }
}

function mergeable(t: Target): boolean {
   return (
      t.selection !== undefined &&
      !t.expanded &&
      !t.loadedAtLaunch &&
      !t.call.conditional &&
      t.call.force !== "inline"
   )
}

function canJoin(group: Target[], t: Target, lines: string[]): boolean {
   const last = group.at(-1)!
   if (!mergeable(group[0]) || !mergeable(t) || t.file !== last.file) return false
   if (t.selection!.start < last.selection!.start) return false
   return readsOnly(lines.slice(last.call.annotationEnd + 1, t.call.line))
}

type Read = { text: string; selection: Selection }

function fitsOneRead(selection: Selection, harness: Harness): boolean {
   return selection.lines.length <= harness.readMaxLines && sizeOf(selection.lines, harness) <= harness.readBudget
}

function splitToFit(span: Selection, harness: Harness): Selection[] {
   const pieces: Selection[] = []
   let first = 0
   while (first < span.lines.length) {
      let last = first
      let size = lineCost(span.lines[first], harness)
      while (last + 1 < span.lines.length && last + 2 - first <= harness.readMaxLines) {
         const grown = size + lineCost(span.lines[last + 1], harness)
         if (grown > harness.readBudget) break
         size = grown
         last++
      }
      const lines = span.lines.slice(first, last + 1)
      pieces.push({ ...span, lines, start: span.start + first, end: span.start + last, limited: true })
      first = last + 1
   }
   return pieces
}

type Settings = { harness: Harness; price: Price; horizon: number; form: PathForm; steering: SteeringModel }

function readsFor(group: Target[], { harness, form }: Settings): Read[] {
   const first = group[0]
   if (group.length === 1 && !first.widened && fitsOneRead(first.selection!, harness))
      return [{ text: harnessCall(first.call, form), selection: first.selection! }]
   const start = Math.min(...group.map((t) => t.selection!.start))
   const end = Math.max(...group.map((t) => t.selection!.end))
   const span = select(first.file!, start, end - start + 1) as Selection
   const style = styleWithRange(first.call.style, harness)
   const path = inForm(writtenPath(first.call), form)
   return splitToFit(span, harness).map((selection) => ({
      text: formatCall(style, path, selection.start, selection.lines.length),
      selection,
   }))
}

type Weighing = { result: string[]; inlineFits: boolean; callTokens: number; inlinedTokens: number; issuedTokens: number }

function weigh(read: Read, name: string, harness: Harness): Weighing {
   const body = renderBody(read.selection, harness)
   const result = wrap(name, body)
   const callTokens = tokens(read.text) + CALL_FRAMING_TOKENS
   const pageSize = lineCost(read.text, harness) + sizeOf(result, harness)
   return {
      result,
      inlineFits: pageSize <= harness.readBudget && result.length < harness.readMaxLines,
      callTokens,
      inlinedTokens: tokens(result.join("\n")) + result.length * harness.lineNumberTokens,
      issuedTokens: callTokens + tokens(body.join("\n")),
   }
}

type Action = { issue?: string[]; inline?: string[] }
type Plan = {
   actions: Map<number, Action>
   inlined: number
   merged: number
   split: number
   dropped: number
   loadedAtLaunch: number
   widened: number
   keptForSteering: number
}
type Price = { output: number; cacheRead: number; cacheWrite: number }

// Reads of instruction files the harness loaded at launch are skipped. A range on any other one is
// dropped: the harness loads such a file whole on its own, a partial read would stop it ever doing
// so, and the file's placement is the project's say, not the outgoing agent's.
function steerTargets(targets: Target[], { harness, steering }: Settings, plan: Plan, warnings: string[]): void {
   for (const t of targets) {
      if (!t.file || !t.selection || t.expanded) continue
      if (steering.launch.has(fileKey(t.file))) {
         t.loadedAtLaunch = true
         if (!t.call.conditional) plan.loadedAtLaunch++
         continue
      }
      if (!harness.steering.onRead || !steering.loadable(t.file)) continue
      const whole = select(t.file, undefined, undefined) as Selection
      if (whole.start === t.selection.start && whole.end === t.selection.end) continue
      if (t.call.conditional) {
         warnings.push(
            `line ${t.call.line + 1}: ${t.call.path} is an instruction file the harness loads whole, ` +
               `and a partial read stops it doing so; if this read fires, read the whole file`,
         )
         continue
      }
      t.selection = whole
      t.widened = true
      plan.widened++
   }
}

type Decision = { group: Target[]; reads: Read[]; weighing: Weighing; inline: boolean; anchor: number }

// inlined content skips the harness's on-read loading, so keep enough reads real to load the same
// instruction files, preferring the reads that cover the most of them
function keepSteeringLoaded(decisions: Decision[], { steering }: Settings, pickup: string, plan: Plan): void {
   const conditional = (d: Decision) => d.group[0].call.conditional
   const loads = (d: Decision) => d.group.flatMap((t) => steering.onRead(t.file!))
   const missing = () => {
      const loaded = new Set(steering.onRead(pickup))
      for (const d of decisions) {
         if (d.inline || conditional(d)) continue
         for (const key of [...loads(d), ...d.group.map((t) => fileKey(t.file!))]) loaded.add(key)
      }
      const delivered = decisions.filter((d) => d.inline || !conditional(d))
      return new Set(delivered.flatMap(loads).filter((key) => !loaded.has(key)))
   }
   for (let gap = missing(); gap.size > 0; gap = missing()) {
      const gain = (d: Decision) => loads(d).filter((key) => gap.has(key)).length
      const candidates = decisions.filter((d) => d.inline && gain(d) > 0)
      const real = candidates.filter((d) => !conditional(d))
      const pool = real.length > 0 ? real : candidates
      if (pool.length === 0) return
      const best = pool.reduce((top, d) => (gain(d) > gain(top) ? d : top))
      best.inline = false
      plan.keptForSteering++
   }
}

function planReads(targets: Target[], lines: string[], settings: Settings, pickup: string, warnings: string[]): Plan {
   const { harness, price, horizon, form, steering } = settings
   const plan: Plan = {
      actions: new Map(),
      inlined: 0,
      merged: 0,
      split: 0,
      dropped: 0,
      loadedAtLaunch: 0,
      widened: 0,
      keptForSteering: 0,
   }
   steerTargets(targets, settings, plan, warnings)
   const carried = price.cacheWrite + price.cacheRead * horizon
   // content is carried either way, so page line numbers weigh against the call (paid as output, then carried)
   const inlineCost = (w: Weighing) => w.inlinedTokens * carried
   const issueCost = (w: Weighing) => w.callTokens * price.output + w.issuedTokens * carried
   // merges stay issued: inlined, a merge's own call line would outweigh the wrapper it saves; and an
   // instruction file inlined would be loaded again by the harness on a later read
   const mayInline = (group: Target[], reads: Read[], w: Weighing) =>
      group.length === 1 &&
      reads.length === 1 &&
      w.inlineFits &&
      group[0].call.force !== "no-inline" &&
      !steering.loadable(group[0].file!)
   const cost = (group: Target[]) => {
      const reads = readsFor(group, settings)
      const weighings = reads.map((read) => weigh(read, group[0].call.style.name, harness))
      const issue = weighings.reduce((sum, w) => sum + issueCost(w), 0)
      return mayInline(group, reads, weighings[0]) ? Math.min(issue, inlineCost(weighings[0])) : issue
   }

   const groups: Target[][] = []
   for (const t of targets) {
      const group = groups.at(-1)
      if (group && canJoin(group, t, lines) && cost([...group, t]) < cost(group) + cost([t])) group.push(t)
      else groups.push([t])
   }

   const covered = targets
      .filter((t) => t.expanded && t.selection)
      .map((t) => ({ file: t.file!, start: t.selection!.start, end: t.selection!.end }))
   const decisions: Decision[] = []
   for (const group of groups) {
      const { call, file, selection, expanded, loadedAtLaunch } = group[0]
      const anchor = group.at(-1)!.call.annotationEnd
      if (expanded || loadedAtLaunch) continue
      if (!selection) {
         if (!call.conditional) plan.actions.set(anchor, { issue: [harnessCall(call, form)] })
         continue
      }
      const reads = readsFor(group, settings)
      const range = { file: file!, start: reads[0].selection.start, end: reads.at(-1)!.selection.end }
      if (covered.some((c) => c.file === range.file && c.start <= range.start && range.end <= c.end)) {
         plan.dropped += group.length
         continue
      }

      const weighing = weigh(reads[0], call.style.name, harness)
      let inline = false
      if (mayInline(group, reads, weighing)) {
         if (call.force === "inline") inline = true
         // an unneeded read wastes context window, which outweighs its price
         else if (call.conditional) inline = weighing.inlinedTokens < call.likelihood * weighing.issuedTokens
         else inline = inlineCost(weighing) < issueCost(weighing)
      } else if (call.force === "inline") {
         const why = steering.loadable(file!) ? "the harness loads it by itself" : "it is too large to inline"
         warnings.push(`line ${call.line + 1}: ${call.path}: ${why}; issued instead`)
      }
      if (call.conditional && !inline) continue
      covered.push(range)
      decisions.push({ group, reads, weighing, inline, anchor })
   }

   if (harness.steering.onRead) keepSteeringLoaded(decisions, settings, pickup, plan)
   for (const { group, reads, weighing, inline, anchor } of decisions) {
      if (group.length > 1) plan.merged += group.length
      else if (reads.length > 1) plan.split++
      if (inline) {
         plan.actions.set(anchor, { inline: weighing.result })
         plan.inlined++
      } else if (!group[0].call.conditional) {
         plan.actions.set(anchor, { issue: reads.map((read) => read.text) })
      }
   }
   return plan
}

function loadPrice(model: string | undefined, ttl: "5m" | "1h", warnings: string[]): Price {
   const writeFactor = ttl === "1h" ? ONE_HOUR_WRITE_FACTOR : 1
   const fallback = {
      output: DEFAULT_PRICE.output,
      cacheRead: DEFAULT_PRICE.cacheRead,
      cacheWrite: DEFAULT_PRICE.cacheWrite5m * writeFactor,
   }
   if (!model) return fallback
   const store = join(process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"), "models-store.json")
   type Cost = { input: number; output: number; cacheRead: number; cacheWrite: number }
   let providers: Record<string, { models?: { id: string; cost?: Cost }[] }>
   try {
      providers = JSON.parse(readFileSync(store, "utf8"))
   } catch (error) {
      warnings.push(`can't read ${store} (${(error as Error).message}); using default prices`)
      return fallback
   }
   for (const [provider, { models = [] }] of Object.entries(providers)) {
      const cost = models.find((m) => m.id === model)?.cost
      if (!cost?.input) continue
      return {
         output: cost.output / cost.input,
         cacheRead: cost.cacheRead / cost.input,
         // only Anthropic sells 1h caching; no write price means plain input
         cacheWrite: ((cost.cacheWrite || cost.input) / cost.input) * (provider === "anthropic" ? writeFactor : 1),
      }
   }
   warnings.push(`no prices for ${model} in ${store}; using default prices`)
   return fallback
}

function guessHarness(calls: ReadCall[]): string {
   const piStyled = calls.filter((c) => c.style.pathKey === "path" || (!c.style.pathKey && c.style.name === "read"))
   return piStyled.length * 2 > calls.length ? "pi" : "claude"
}

// a positional call has no syntax for offset and limit to copy
function styleWithRange(style: CallStyle, harness: Harness): CallStyle {
   return style.kind === "positional" ? { ...harness.defaultStyle, name: style.name } : style
}

function mirrorStyle(calls: ReadCall[], harness: Harness): CallStyle {
   const style = calls.find((c) => c.style.kind !== "positional")?.style ?? calls[0]?.style ?? harness.defaultStyle
   return styleWithRange(style, harness)
}

function formatCall(style: CallStyle, path: string, offset: number, limit: number): string {
   if (style.kind === "json")
      return `${style.name}({"${style.pathKey}": ${JSON.stringify(path)}, "offset": ${offset}, "limit": ${limit}})`
   const quote = style.quote || (/\s/.test(path) ? '"' : "")
   return `${style.name}(${style.pathKey}=${quote}${path}${quote}, offset=${offset}, limit=${limit})`
}

// never break a page between a result and the call it answers
function resultSpans(out: string[]): Set<number> {
   const spans = new Set<number>()
   for (let r = 0; r < out.length; r++) {
      if (out[r].trim() !== "<result>") continue
      let from = r - 1
      while (from > 0 && isAnnotation(out[from])) from--
      let close = r
      while (close < out.length - 1 && out[close].trim() !== "</result>") close++
      for (let k = from; k < close; k++) spans.add(k)
      r = close
   }
   return spans
}

type Page = { start: number; end: number }

// break where the successor issues a read itself, so results arrive in document order
function paginate(
   out: string[],
   issued: Map<number, string[]>,
   noPageBreakAfter: Set<number>,
   harness: Harness,
): (Page | string)[] {
   const plan: (Page | string)[] = []
   const last = out.at(-1) === "" ? out.length - 2 : out.length - 1
   let start = 0
   let size = 0
   const closePage = (end: number) => {
      if (out.slice(start, end + 1).some((line) => line.trim() !== "")) plan.push({ start, end })
      start = end + 1
   }
   for (let i = 0; i <= last; i++) {
      if (i > start && (size + lineCost(out[i], harness) > harness.readBudget || i - start >= harness.readMaxLines)) {
         let end = i - 1
         while (end > start && noPageBreakAfter.has(end)) end--
         closePage(end)
         size = sizeOf(out.slice(start, i), harness)
      }
      size += lineCost(out[i], harness)
      if (!issued.has(i)) continue
      const run = issuedRun(out, issued, i, last, harness.readBudget - size, harness)
      closePage(run.end)
      plan.push(...run.reads)
      i = run.end
      size = 0
   }
   if (start <= last) closePage(last)
   return plan
}

function issuedRun(
   out: string[],
   issued: Map<number, string[]>,
   first: number,
   last: number,
   room: number,
   harness: Harness,
): { reads: string[]; end: number } {
   const reads = [...issued.get(first)!]
   let end = first
   let gapSize = 0
   for (let k = first + 1; k <= last; k++) {
      gapSize += lineCost(out[k], harness)
      if (gapSize > room) break
      if (!issued.has(k)) continue
      if (!readsOnly(out.slice(end + 1, k + 1))) break
      reads.push(...issued.get(k)!)
      end = k
      room -= gapSize
      gapSize = 0
   }
   return { reads, end }
}

export type ExpandOptions = {
   pickupPath: string
   harness?: string | Harness
   model?: string
   cacheTtl?: "5m" | "1h"
   horizon?: number
   paths?: PathForm
   cwd?: string
   env?: NodeJS.ProcessEnv
}

export type Expansion = {
   output: string
   batch: string[]
   warnings: string[]
   reads: number
   inlined: number
   merged: number
   split: number
   dropped: number
   loadedAtLaunch: number
   widened: number
   keptForSteering: number
   pages: number
   estimatedTokens: number
}

export function expand(handoff: string, options: ExpandOptions): Expansion {
   const eol = handoff.includes("\r\n") ? "\r\n" : "\n"
   const lines = handoff.split(/\r?\n/)
   const warnings: string[] = []
   const calls: ReadCall[] = []
   for (let i = 0; i < lines.length; i++) {
      // an earlier run's inlined results may quote reads
      if (lines[i].trim() === "<result>") {
         while (i < lines.length - 1 && lines[i].trim() !== "</result>") i++
         continue
      }
      const call = parseCall(lines, i)
      if (call === "malformed") {
         warnings.push(`line ${i + 1} looks like a read but doesn't parse; left as written, not batched: ${lines[i].trim()}`)
      } else if (call) {
         calls.push(call)
         i = call.annotationEnd
      }
   }

   const harness =
      typeof options.harness === "object" ? options.harness : HARNESSES[options.harness ?? guessHarness(calls)]
   const settings: Settings = {
      harness,
      price: loadPrice(options.model, options.cacheTtl ?? harness.cacheTtl, warnings),
      horizon: options.horizon ?? DEFAULT_HORIZON_REQUESTS,
      form: options.paths ?? localForm(),
      steering: steeringModel(harness.steering, options.cwd ?? process.cwd(), options.env ?? process.env),
   }
   const targets = calls.map((call) => resolveTarget(call, lines, warnings))
   const plan = planReads(targets, lines, settings, resolve(options.pickupPath), warnings)

   const out: string[] = []
   const issued = new Map<number, string[]>() // keyed by output line
   for (let i = 0; i < lines.length; i++) {
      out.push(lines[i])
      const action = plan.actions.get(i)
      if (action?.issue) issued.set(out.length - 1, action.issue)
      if (action?.inline) out.push(...action.inline)
   }

   const steps = paginate(out, issued, resultSpans(out), harness)
   const style = mirrorStyle(calls, harness)
   const pickup = inForm(resolve(options.pickupPath), settings.form)
   const batch = steps.map((step) =>
      typeof step === "string" ? step : formatCall(style, pickup, step.start + 1, step.end - step.start + 1),
   )
   const output = out.join(eol)
   return {
      output,
      batch,
      warnings,
      reads: calls.length,
      inlined: plan.inlined,
      merged: plan.merged,
      split: plan.split,
      dropped: plan.dropped,
      loadedAtLaunch: plan.loadedAtLaunch,
      widened: plan.widened,
      keptForSteering: plan.keptForSteering,
      pages: steps.filter((step) => typeof step !== "string").length,
      estimatedTokens: tokens(output) + out.length * harness.lineNumberTokens,
   }
}

export function callingHarness(env = process.env): string | undefined {
   if (env.PI_SESSION_ID) return "pi"
   if (env.CLAUDECODE) return "claude"
   return undefined
}

// pi exports the model; Claude Code doesn't, but logs the call running this before running it
export function callingModel(env = process.env): string | undefined {
   if (env.PI_MODEL) return env.PI_MODEL
   const session = env.CLAUDE_CODE_SESSION_ID
   if (!session) return undefined
   const projects = join(env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"), "projects")
   if (!existsSync(projects)) return undefined
   for (const project of readdirSync(projects)) {
      const transcript = join(projects, project, `${session}.jsonl`)
      if (!existsSync(transcript)) continue
      const entries = readFileSync(transcript, "utf8").trimEnd().split("\n")
      for (const entry of entries.reverse()) {
         let model: unknown
         try {
            model = JSON.parse(entry).message?.model
         } catch {
            continue
         }
         // Claude Code logs its own notices as "<synthetic>"
         if (typeof model === "string" && !model.startsWith("<")) return model
      }
   }
   return undefined
}

function sameFile(a: string, b: string): boolean {
   if (a === b) return true
   if (!existsSync(a) || !existsSync(b)) return false
   const [x, y] = [a, b].map((path) => statSync(path, { bigint: true }))
   return x.ino !== 0n && x.ino === y.ino && x.dev === y.dev
}

function main(): void {
   const fail = (message: string): never => {
      process.stderr.write(`expand-handoff: ${message}\n\n${USAGE}`)
      process.exit(2)
   }
   let parsed
   try {
      parsed = parseArgs({
         options: {
            in: { type: "string" },
            out: { type: "string" },
            harness: { type: "string" },
            model: { type: "string" },
            horizon: { type: "string" },
            "cache-ttl": { type: "string" },
            paths: { type: "string" },
            help: { type: "boolean", short: "h" },
         },
      })
   } catch (error) {
      return fail((error as Error).message)
   }
   const { values } = parsed
   if (values.help) {
      process.stdout.write(USAGE)
      return
   }
   if (values.in === undefined || values.out === undefined) fail("give both --in <handoff-path> and --out <pickup-path>")
   if (values.harness !== undefined && !(values.harness in HARNESSES))
      fail(`--harness must be one of: ${Object.keys(HARNESSES).join(", ")}`)
   const ttl = values["cache-ttl"]
   if (ttl !== undefined && ttl !== "5m" && ttl !== "1h") fail("--cache-ttl must be 5m or 1h")
   const horizon = values.horizon === undefined ? undefined : Number(values.horizon)
   if (horizon !== undefined && !(Number.isInteger(horizon) && horizon >= 0))
      fail("--horizon must be a whole number of requests")
   const paths = values.paths
   if (paths !== undefined && paths !== "windows" && paths !== "posix") fail("--paths must be windows or posix")
   const handoffPath = resolve(inForm(values.in!, localForm()))
   const pickupPath = resolve(inForm(values.out!, localForm()))
   if (sameFile(handoffPath, pickupPath)) fail("--out is the handoff itself; give the pickup a path of its own")
   let handoff = ""
   try {
      handoff = readFileSync(handoffPath, "utf8")
   } catch (error) {
      fail(`can't read --in: ${(error as Error).message}`)
   }
   if (!handoff.trim()) fail(`--in is empty: ${handoffPath}`)

   const result = expand(handoff, {
      pickupPath,
      harness: values.harness ?? callingHarness(),
      model: values.model ?? callingModel(),
      cacheTtl: ttl as "5m" | "1h" | undefined,
      horizon,
      paths: paths as PathForm | undefined,
   })
   writeFileSync(pickupPath, result.output)

   const summary = [`inlined ${result.inlined} of ${result.reads} reads`]
   if (result.merged) summary.push(`merged ${result.merged} into fewer`)
   if (result.split) summary.push(`split ${result.split} too large for one read`)
   if (result.dropped) summary.push(`dropped ${result.dropped} already covered`)
   if (result.loadedAtLaunch) summary.push(`skipped ${result.loadedAtLaunch} instruction files loaded at launch`)
   if (result.widened) summary.push(`read ${result.widened} range-limited instruction files whole`)
   if (result.keptForSteering) summary.push(`kept ${result.keptForSteering} reads real so their instruction files load`)
   summary.push(`${result.pages} page(s), about ${Math.round(result.estimatedTokens / 1000)}k tokens`)
   for (const warning of result.warnings) process.stderr.write(`expand-handoff: warning: ${warning}\n`)
   process.stderr.write(`expand-handoff: ${summary.join("; ")}.\n`)
   process.stdout.write(["Read all these in a single turn:", ...result.batch].join("\n") + "\n")
}

if (import.meta.main) main()
