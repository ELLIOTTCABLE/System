#!/usr/bin/env node
import { existsSync, fstatSync, readFileSync, statSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join, resolve } from "node:path"
import { parseArgs } from "node:util"

// per token, relative to uncached input; `--model` reads real ones from pi's store
const DEFAULT_PRICE = { output: 5, cacheRead: 0.1, cacheWrite5m: 1.25 }
// 1h cache writes bill 2x input, 5m ones 1.25x; pi's store lists 5m
const ONE_HOUR_WRITE_FACTOR = 2 / 1.25
const DEFAULT_HORIZON_REQUESTS = 150
const DEFAULT_CONDITIONAL_LIKELIHOOD = 0.3
const CHARS_PER_TOKEN = 4
// tool-use id and block, plus result wrapper, beyond the call's visible text
const CALL_FRAMING_TOKENS = 25
// shorter text between issued reads rides the earlier read's page, landing before its result,
// rather than costing a page read of its own
const MERGE_GAP_TOKENS = 300
const READ_TOOL_NAMES = ["Read", "read"]
const PATH_KEYS = ["file_path", "path", "filePath", "file"]
// harness injects these on entering their directory; inlining would carry them twice
const NEVER_INLINE = ["CLAUDE.md", "CLAUDE.local.md", "AGENTS.md"]

type CallStyle = { kind: "kwargs" | "json" | "positional"; name: string; pathKey: string; quote: string }

export type Harness = {
   defaultStyle: CallStyle
   numbered: boolean // `N<TAB>line`, so reading a page numbers its inlined lines a second time
   lineNumberTokens: number
   readBudget: number
   readUnit: "chars" | "bytes"
   readMaxLines: number
   cacheTtl: "5m" | "1h"
   moreLinesNotice: boolean
}

export const HARNESSES: Record<string, Harness> = {
   claude: {
      defaultStyle: { kind: "kwargs", name: "Read", pathKey: "file_path", quote: '"' },
      numbered: true,
      lineNumberTokens: 2,
      readBudget: 60_000, // Read refuses results over 25k tokens; chars only track that loosely

      readUnit: "chars",
      readMaxLines: 2000,
      cacheTtl: "1h",
      moreLinesNotice: false,
   },
   pi: {
      defaultStyle: { kind: "kwargs", name: "read", pathKey: "path", quote: '"' },
      numbered: false,
      lineNumberTokens: 0,
      readBudget: 48_000, // pi truncates reads at 50KB
      readUnit: "bytes",
      readMaxLines: 2000,
      cacheTtl: "5m",
      moreLinesNotice: true,
   },
}

const USAGE = `Usage: node expand-handoff.mts <pickup-path> [options] < <handoff>

Copies a handoff from stdin into a pickup document at <pickup-path>. Where the handoff dictates
a read, the read's result is inlined after it if carrying the result pre-read costs the successor
less than issuing the read. Nothing else in the handoff changes. Stdout gets the one batch of
reads that delivers the whole document in order: its pages, interleaved with the reads left
un-inlined. Stderr gets any warnings and a summary.

  <pickup-path>        where to write the pickup document; the page reads point at it
  --harness claude|pi  the harness that will read the pickup (default: guessed from the reads)
  --model <id>         price ratios for this model, from pi's model store
  --horizon <n>        requests the successor makes after standing up (default ${DEFAULT_HORIZON_REQUESTS})
  --cache-ttl 5m|1h    the successor's prompt-cache lifetime (default: 1h for claude, 5m for pi)

A read is a line that holds one read call, optionally bulleted or in backticks:
  Read(file_path="C:\\notes\\a.md", offset=10, limit=20)
  read(path="/notes/a.md")
  Read(notes/a.md)
  Read({"file_path": "C:\\\\notes\\\\a.md", "offset": 10})
Its annotation is the rest of that line plus any indented lines directly below it. An inlined
result goes after the annotation. The annotation stays as written, and may carry:
  [when] <trigger>  a conditional read, issued only if the trigger fires, so never batched;
                    only this tag (or [p=…]) makes a read conditional, never prose like "when:"
  [p=0.2]           the chance a conditional read's trigger fires (default ${DEFAULT_CONDITIONAL_LIKELIHOOD})
  [inline]          inline even where the cost model says not to
  [no-inline]       never inline
${NEVER_INLINE.join(" and ")} are never inlined, as the harness loads them by itself.
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
   force?: "inline" | "read"
}

const CALL_START = /^(\s*(?:[-*+]\s+|\d+[.)]\s+)?`*)([A-Za-z_]\w*)\s*\(/

function readCallStart(line: string): RegExpExecArray | undefined {
   const start = CALL_START.exec(line)
   return start && READ_TOOL_NAMES.includes(start[2]) ? start : undefined
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
   while (/^\s+\S/.test(lines[annotationEnd + 1] ?? "") && !readCallStart(lines[annotationEnd + 1])) annotationEnd++
   const annotation = [line.slice(close + 1), ...lines.slice(index + 1, annotationEnd + 1)].join("\n")
   // only explicit tags: a mandatory read mistaken for conditional leaves the successor reasoning from a
   // partial foundation, which is far worse than an unneeded read
   const likelihood = /\[p\s*=\s*(1(?:\.0*)?|0?\.\d+|0)\]/i.exec(annotation)?.[1]
   const conditional = likelihood !== undefined || /\[when\]/i.test(annotation)
   return {
      line: index,
      annotationEnd,
      text: line.slice(start[1].length, close + 1),
      style: { ...args.style, name: start[2] },
      path: args.path,
      offset: args.offset,
      limit: args.limit,
      conditional,
      likelihood: conditional ? Number(likelihood ?? DEFAULT_CONDITIONAL_LIKELIHOOD) : 1,
      force: /\[no-inline\]/i.test(annotation) ? "read" : /\[inline\]/i.test(annotation) ? "inline" : undefined,
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
   const offset = lineCount(byKey.get("offset")?.value)
   const limit = lineCount(byKey.get("limit")?.value)
   if (!pathKey || offset === null || limit === null) return undefined
   const path = byKey.get(pathKey)!
   return { style: { kind, pathKey, quote: path.quote }, path: path.value, offset, limit }
}

function lineCount(value: string | undefined): number | undefined | null {
   if (value === undefined) return undefined
   const n = Number(value)
   return Number.isInteger(n) && n >= 0 ? n : null
}

// handoff paths may be written for another shell or OS than this one
function locate(path: string): string | undefined {
   const unescaped = path.replace(/\\\\/g, "\\")
   const candidates = [path, unescaped]
   const posixDrive = /^\/(?:mnt\/)?([a-zA-Z])\/(.*)$/.exec(unescaped)
   if (posixDrive && process.platform === "win32") candidates.push(`${posixDrive[1]}:/${posixDrive[2]}`)
   const windowsDrive = /^([a-zA-Z]):[\\/](.*)$/.exec(unescaped)
   if (windowsDrive && process.platform !== "win32")
      candidates.push(`/mnt/${windowsDrive[1].toLowerCase()}/${windowsDrive[2].replace(/\\/g, "/")}`)
   if (/^~[\\/]/.test(unescaped)) candidates.push(join(homedir(), unescaped.slice(2)))
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
   return size + 1 + (harness.numbered ? 7 : 0)
}

const tokens = (text: string) => Math.ceil(text.length / CHARS_PER_TOKEN)

type Price = { output: number; cacheRead: number; cacheWrite: number }

type Target = { call: ReadCall; file?: string; selection?: Selection; expanded: boolean }

function target(call: ReadCall, lines: string[], warnings: string[]): Target {
   const expanded = lines[call.annotationEnd + 1]?.trim() === "<result>"
   const file = locate(call.path)
   if (!file) {
      warnings.push(`line ${call.line + 1}: can't find ${call.path}; left for the successor to read as written`)
      return { call, expanded }
   }
   const selection = select(file, call.offset, call.limit)
   if (typeof selection === "string") {
      warnings.push(`line ${call.line + 1}: ${call.path}: ${selection}; left as written`)
      return { call, expanded }
   }
   return { call, file, selection, expanded }
}

const neverInline = (call: ReadCall) => NEVER_INLINE.includes(call.path.split(/[\\/]/).at(-1)!)

const mergeable = (t: Target) =>
   t.selection !== undefined && !t.expanded && !t.call.conditional && !t.call.force && !neverInline(t.call)

type Weighing = { result: string[]; fits: boolean; callTokens: number; inlinedTokens: number; issuedTokens: number }

function weigh(text: string, name: string, selection: Selection, harness: Harness): Weighing {
   const body = renderBody(selection, harness)
   const result = wrap(name, body)
   const callTokens = tokens(text) + CALL_FRAMING_TOKENS
   const size = result.reduce((sum, line) => sum + lineCost(line, harness), lineCost(text, harness))
   return {
      result,
      fits: size <= harness.readBudget && result.length < harness.readMaxLines,
      callTokens,
      inlinedTokens: tokens(result.join("\n")) + result.length * harness.lineNumberTokens,
      issuedTokens: callTokens + tokens(body.join("\n")),
   }
}

function unite(group: Target[], harness: Harness): { text: string; selection: Selection; weighing: Weighing } {
   const first = group[0]
   let text = first.call.text
   let selection = first.selection!
   if (group.length > 1) {
      const start = Math.min(...group.map((t) => t.selection!.start))
      const end = Math.max(...group.map((t) => t.selection!.end))
      const style = first.call.style.kind === "positional" ? { ...harness.defaultStyle, name: first.call.style.name } : first.call.style
      text = formatCall(style, first.call.path, start, end - start + 1)
      selection = select(first.file!, start, end - start + 1) as Selection
   }
   return { text, selection, weighing: weigh(text, first.call.style.name, selection, harness) }
}

type Action = { issue?: string; inline?: string[] }
type Plan = { actions: Map<number, Action>; inlined: number; merged: number; dropped: number }

function planReads(
   targets: Target[],
   lines: string[],
   harness: Harness,
   price: Price,
   horizon: number,
   warnings: string[],
): Plan {
   const carried = price.cacheWrite + price.cacheRead * horizon
   // content is carried either way, so page line numbers weigh against the call (paid as output, then carried)
   const inlineCost = (w: Weighing) => w.inlinedTokens * carried
   const issueCost = (w: Weighing) => w.callTokens * price.output + w.issuedTokens * carried
   // merges are always issued: inlined, a merge's own call line would outweigh the wrapper it saves
   const cost = (group: Target[]) => {
      const { weighing } = unite(group, harness)
      const issue = issueCost(weighing)
      return group.length > 1 || !weighing.fits ? issue : Math.min(issue, inlineCost(weighing))
   }
   const joins = (group: Target[], t: Target) => {
      const last = group.at(-1)!
      if (!mergeable(group[0]) || !mergeable(t) || t.file !== last.file) return false
      if (t.selection!.start < last.selection!.start) return false
      if (tokens(lines.slice(last.call.annotationEnd + 1, t.call.line).join("\n")) > MERGE_GAP_TOKENS) return false
      const merged = [...group, t]
      return unite(merged, harness).weighing.fits && cost(merged) < cost(group) + cost([t])
   }
   const groups: Target[][] = []
   for (const t of targets) {
      const group = groups.at(-1)
      if (group && joins(group, t)) group.push(t)
      else groups.push([t])
   }

   type Range = { file: string; start: number; end: number }
   const covered: Range[] = targets
      .filter((t) => t.expanded && t.selection)
      .map((t) => ({ file: t.file!, start: t.selection!.start, end: t.selection!.end }))
   const plan: Plan = { actions: new Map(), inlined: 0, merged: 0, dropped: 0 }
   for (const group of groups) {
      const { call, selection: own, expanded } = group[0]
      const anchor = group.at(-1)!.call.annotationEnd
      if (expanded) continue
      if (!own) {
         if (!call.conditional) plan.actions.set(anchor, { issue: call.text })
         continue
      }
      const { text, selection, weighing } = unite(group, harness)
      const range = { file: group[0].file!, start: selection.start, end: selection.end }
      if (covered.some((c) => c.file === range.file && c.start <= range.start && range.end <= c.end)) {
         plan.dropped += group.length
         continue
      }
      if (!weighing.fits)
         warnings.push(
            `line ${call.line + 1}: ${call.path} lines ${selection.start}-${selection.end} may be more than one read ` +
               `returns, so the successor may get it truncated`,
         )
      let inline = false
      if (group.length === 1 && weighing.fits && call.force !== "read" && !neverInline(call)) {
         if (call.force === "inline") inline = true
         // an unneeded read wastes context window, which outweighs its price
         else if (call.conditional) inline = weighing.inlinedTokens < call.likelihood * weighing.issuedTokens
         else inline = inlineCost(weighing) < issueCost(weighing)
      }
      if (call.conditional && !inline) continue
      covered.push(range)
      if (group.length > 1) plan.merged += group.length
      if (!inline) plan.actions.set(anchor, { issue: text })
      else {
         plan.actions.set(anchor, { inline: weighing.result })
         plan.inlined++
      }
   }
   return plan
}

// never break between a result and the call it answers
function resultSpans(out: string[]): Set<number> {
   const spans = new Set<number>()
   for (let r = 0; r < out.length; r++) {
      if (out[r].trim() !== "<result>") continue
      let from = r - 1
      while (from > 0 && /^\s+\S/.test(out[from]) && !readCallStart(out[from])) from--
      let close = r
      while (close < out.length - 1 && out[close].trim() !== "</result>") close++
      for (let k = from; k < close; k++) spans.add(k)
      r = close
   }
   return spans
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

function mirrorStyle(calls: ReadCall[], harness: Harness): CallStyle {
   const keyed = calls.find((c) => c.style.kind !== "positional")
   return keyed?.style ?? { ...harness.defaultStyle, name: calls[0]?.style.name ?? harness.defaultStyle.name }
}

function formatCall(style: CallStyle, path: string, offset: number, limit: number): string {
   if (style.kind === "json")
      return `${style.name}({"${style.pathKey}": ${JSON.stringify(path)}, "offset": ${offset}, "limit": ${limit}})`
   const quote = style.quote || (/\s/.test(path) ? '"' : "")
   return `${style.name}(${style.pathKey}=${quote}${path}${quote}, offset=${offset}, limit=${limit})`
}

type Page = { start: number; end: number }

// break where the successor issues a read itself, so results arrive in document order
function paginate(
   out: string[],
   issued: Map<number, string>,
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
      const cost = lineCost(out[i], harness)
      if (i > start && (size + cost > harness.readBudget || i - start >= harness.readMaxLines)) {
         let end = i - 1
         while (end > start && noPageBreakAfter.has(end)) end--
         closePage(end)
         size = 0
         for (let k = start; k < i; k++) size += lineCost(out[k], harness)
      }
      size += cost
      if (!issued.has(i)) continue
      const run = [issued.get(i)!]
      let end = i
      let gapTokens = 0
      let gapSize = 0
      for (let k = i + 1; k <= last; k++) {
         if (issued.has(k)) {
            if (size + gapSize + lineCost(out[k], harness) > harness.readBudget) break
            run.push(issued.get(k)!)
            end = k
            size += gapSize + lineCost(out[k], harness)
            gapTokens = gapSize = 0
            continue
         }
         gapTokens += tokens(out[k])
         gapSize += lineCost(out[k], harness)
         if (gapTokens > MERGE_GAP_TOKENS) break
      }
      closePage(end)
      plan.push(...run)
      i = end
      size = 0
   }
   if (start <= last) closePage(last)
   return plan
}

export type ExpandOptions = {
   pickupPath: string
   harness?: string | Harness
   model?: string
   cacheTtl?: "5m" | "1h"
   horizon?: number
}

export type Expansion = {
   output: string
   batch: string[]
   warnings: string[]
   reads: number
   inlined: number
   merged: number
   dropped: number
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
      if (call === "malformed")
         warnings.push(`line ${i + 1} looks like a read but doesn't parse; left as written, not batched: ${lines[i].trim()}`)
      else if (call) {
         calls.push(call)
         i = call.annotationEnd
      }
   }

   const harness =
      typeof options.harness === "object" ? options.harness : HARNESSES[options.harness ?? guessHarness(calls)]
   const price = loadPrice(options.model, options.cacheTtl ?? harness.cacheTtl, warnings)
   const horizon = options.horizon ?? DEFAULT_HORIZON_REQUESTS
   const targets = calls.map((call) => target(call, lines, warnings))
   const { actions, inlined, merged, dropped } = planReads(targets, lines, harness, price, horizon, warnings)

   const out: string[] = []
   const issued = new Map<number, string>() // keyed by output line
   for (let i = 0; i < lines.length; i++) {
      out.push(lines[i])
      const action = actions.get(i)
      if (action?.issue) issued.set(out.length - 1, action.issue)
      if (action?.inline) out.push(...action.inline)
   }

   const plan = paginate(out, issued, resultSpans(out), harness)
   const style = mirrorStyle(calls, harness)
   const pickup = resolve(options.pickupPath)
   const batch = plan.map((step) =>
      typeof step === "string" ? step : formatCall(style, pickup, step.start + 1, step.end - step.start + 1),
   )
   const output = out.join(eol)
   return {
      output,
      batch,
      warnings,
      reads: calls.length,
      inlined,
      merged,
      dropped,
      pages: plan.filter((step) => typeof step !== "string").length,
      estimatedTokens: tokens(output) + out.length * harness.lineNumberTokens,
   }
}

function main(): void {
   const fail = (message: string): never => {
      process.stderr.write(`expand-handoff: ${message}\n\n${USAGE}`)
      process.exit(2)
   }
   let parsed
   try {
      parsed = parseArgs({
         allowPositionals: true,
         options: {
            harness: { type: "string" },
            model: { type: "string" },
            horizon: { type: "string" },
            "cache-ttl": { type: "string" },
            help: { type: "boolean", short: "h" },
         },
      })
   } catch (error) {
      return fail((error as Error).message)
   }
   const { values, positionals } = parsed
   if (values.help) return void process.stdout.write(USAGE)
   if (positionals.length !== 1) fail("give exactly one argument: the path to write the pickup document to")
   if (values.harness !== undefined && !(values.harness in HARNESSES))
      fail(`--harness must be one of: ${Object.keys(HARNESSES).join(", ")}`)
   const ttl = values["cache-ttl"]
   if (ttl !== undefined && ttl !== "5m" && ttl !== "1h") fail("--cache-ttl must be 5m or 1h")
   const horizon = values.horizon === undefined ? undefined : Number(values.horizon)
   if (horizon !== undefined && !(Number.isInteger(horizon) && horizon >= 0))
      fail("--horizon must be a whole number of requests")
   if (process.stdin.isTTY) fail("redirect the handoff into stdin")
   const pickupPath = resolve(positionals[0])
   if (isStdin(pickupPath)) fail("<pickup-path> is the handoff itself; give the pickup a path of its own")
   const handoff = readFileSync(0, "utf8")
   if (!handoff.trim()) fail("stdin was empty; redirect the handoff into it")

   const result = expand(handoff, {
      pickupPath,
      harness: values.harness,
      model: values.model,
      cacheTtl: ttl as "5m" | "1h" | undefined,
      horizon,
   })
   writeFileSync(pickupPath, result.output)
   const report = [
      ...result.warnings.map((warning) => `expand-handoff: warning: ${warning}`),
      `expand-handoff: inlined ${result.inlined} of ${result.reads} reads; ` +
         (result.merged ? `merged ${result.merged} into fewer; ` : "") +
         (result.dropped ? `dropped ${result.dropped} already covered; ` : "") +
         `${result.pages} page(s), about ${Math.round(result.estimatedTokens / 1000)}k tokens.`,
   ]
   process.stderr.write(report.join("\n") + "\n")
   process.stdout.write(["Read all these in a single turn:", ...result.batch].join("\n") + "\n")
}

function isStdin(path: string): boolean {
   if (!existsSync(path)) return false
   const stdin = fstatSync(0, { bigint: true })
   const file = statSync(path, { bigint: true })
   return stdin.ino !== 0n && stdin.ino === file.ino && stdin.dev === file.dev
}

if (import.meta.main) main()
