// What a harness loads into context by itself: instruction files (CLAUDE.md, AGENTS.md, rules) and
// their imports, at launch and on reads. Mirrors Claude Code 2.1.291 (docs, source, and live tests)
// and pi's resource loader; see ledger.md.
import { existsSync, readdirSync, readFileSync, realpathSync, statSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, extname, isAbsolute, join, matchesGlob, relative, resolve, sep } from "node:path"
import braces from "braces"
import ignore from "ignore"
import YAML from "yaml"

export type SteeringProfile = {
   // looked for in each directory from the filesystem root down to the launch directory
   names: string[]
   // gitignored, so loaded even from a main repo above a nested worktree
   localNames: string[]
   // load only the first of `names` that exists in each directory, not all of them
   firstOnly: boolean
   userDir: (env: NodeJS.ProcessEnv) => string
   userNames: string[]
   // also load `names` (and rules) for each directory between the launch directory and a file read
   onRead: boolean
   rulesDir?: string
   imports?: { maxDepth: number; extensions: string[] }
   // Claude Code reads AGENTS.md instead of, or as well as, CLAUDE.md, depending on a user setting
   agents?: { launchNames: string[]; onReadNames: string[]; defaultMode: AgentsMode }
   managed?: Partial<Record<string, string>>
   worktrees: "skip-main-repo-files" | "shadow-main-repo-file"
}

type AgentsMode = "claude-md-or-agents-md" | "claude-md-and-agents-md" | "claude-md" | "managed-only"

// Claude Code skips @-imports of anything else
const CLAUDE_IMPORT_EXTENSIONS = (
   ".md .txt .text .json .yaml .yml .toml .xml .csv .html .htm .css .scss .sass .less .js .ts .tsx .jsx .mjs " +
   ".cjs .mts .cts .py .pyi .pyw .rb .erb .rake .go .rs .java .kt .kts .scala .c .cpp .cc .cxx .h .hpp .hxx .cs " +
   ".swift .sh .bash .zsh .fish .ps1 .bat .cmd .env .ini .cfg .conf .config .properties .sql .graphql .gql " +
   ".proto .vue .svelte .astro .ejs .hbs .pug .jade .php .pl .pm .lua .r .dart .ex .exs .erl .hrl .clj .cljs " +
   ".cljc .edn .hs .lhs .elm .ml .mli .f .f90 .f95 .for .cmake .make .makefile .gradle .sbt .rst .adoc " +
   ".asciidoc .org .tex .latex .lock .log .diff .patch"
).split(" ")

const PI_NAMES = ["AGENTS.override.md", "AGENTS.md", "AGENTS.MD", "CLAUDE.md", "CLAUDE.MD"]

export const STEERING: Record<string, SteeringProfile> = {
   claude: {
      names: ["CLAUDE.md", ".claude/CLAUDE.md"],
      localNames: ["CLAUDE.local.md"],
      firstOnly: false,
      userDir: (env) => env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"),
      userNames: ["CLAUDE.md"],
      onRead: true,
      rulesDir: ".claude/rules",
      imports: { maxDepth: 5, extensions: CLAUDE_IMPORT_EXTENSIONS },
      agents: {
         launchNames: ["AGENTS.md", ".claude/AGENTS.md"],
         onReadNames: ["AGENTS.md"],
         defaultMode: "claude-md-or-agents-md",
      },
      managed: {
         darwin: "/Library/Application Support/ClaudeCode/CLAUDE.md",
         linux: "/etc/claude-code/CLAUDE.md",
         win32: "C:\\Program Files\\ClaudeCode\\CLAUDE.md",
      },
      worktrees: "skip-main-repo-files",
   },
   pi: {
      names: PI_NAMES,
      localNames: [],
      firstOnly: true,
      userDir: (env) => env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"),
      userNames: PI_NAMES,
      onRead: false,
      worktrees: "shadow-main-repo-file",
   },
}

export type SteeringModel = {
   // files in context from launch
   launch: Set<string>
   // files a real read of `file` makes the harness load, beyond those already loaded at launch
   onRead(file: string): string[]
   // whether the harness could ever load `file` by itself
   loadable(file: string): boolean
}

// realpath, so a CLAUDE.md symlinked to AGENTS.md is one file; casefolded where the filesystem is
export function fileKey(path: string): string {
   let real = resolve(path)
   try {
      real = realpathSync.native(real)
   } catch {}
   return process.platform === "win32" ? real.toLowerCase() : real
}

function isFile(path: string): boolean {
   try {
      return statSync(path).isFile()
   } catch {
      return false
   }
}

function readText(path: string): string {
   return readFileSync(path, "utf8").replace(/^\uFEFF/, "")
}

function readJson(path: string): any {
   try {
      return JSON.parse(readText(path))
   } catch {
      return undefined
   }
}

function inside(dir: string, path: string): boolean {
   const rel = relative(dir, path)
   return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel))
}

// from the filesystem root down to `dir`
function ancestry(dir: string): string[] {
   const dirs = [resolve(dir)]
   while (dirname(dirs[0]) !== dirs[0]) dirs.unshift(dirname(dirs[0]))
   return dirs
}

// directories strictly below `cwd`, down to the directory holding `file`
function nestedDirs(cwd: string, file: string): string[] {
   const dir = dirname(resolve(file))
   if (!inside(cwd, dir) || fileKey(dir) === fileKey(cwd)) return []
   return ancestry(dir).filter((d) => inside(cwd, d) && fileKey(d) !== fileKey(cwd))
}

// @-imports outside code; Claude Code lexes markdown, which this approximates
export function importsOf(file: string, text: string): string[] {
   const prose = text
      .replace(/^(```|~~~)[^\n]*\n[\s\S]*?^\1[^\n]*$/gm, "")
      .replace(/`[^`\n]*`/g, "")
      .replace(/<!--[\s\S]*?-->/g, "")
   const paths: string[] = []
   for (const [, raw] of prose.matchAll(/(?:^|\s)@((?:[^\s\\]|\\ )+)/g)) {
      const path = raw.split("#")[0].replace(/\\ /g, " ")
      const valid =
         path.startsWith("./") ||
         path.startsWith("~/") ||
         (path.startsWith("/") && path !== "/") ||
         (/^[a-zA-Z0-9._-]/.test(path) && !path.startsWith("@"))
      if (!path || !valid) continue
      paths.push(path.startsWith("~/") ? join(homedir(), path.slice(2)) : resolve(dirname(file), path))
   }
   return paths
}

// a rule's `paths` frontmatter as gitignore-style patterns, or undefined when it applies everywhere
export function rulePatterns(text: string): string[] | undefined {
   const frontmatter = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text)
   if (!frontmatter) return undefined
   let paths: unknown
   try {
      paths = YAML.parse(frontmatter[1])?.paths
   } catch {
      return undefined
   }
   const patterns = splitPatterns(paths)
      .flatMap((pattern) => braces.expand(pattern))
      .map((pattern) => (pattern.endsWith("/**") ? pattern.slice(0, -3) : pattern))
      .filter((pattern) => pattern !== "")
   if (patterns.length === 0 || patterns.every((pattern) => pattern === "**")) return undefined
   return patterns
}

// commas split patterns, except inside braces
function splitPatterns(value: unknown): string[] {
   if (Array.isArray(value)) return value.flatMap(splitPatterns)
   if (typeof value !== "string") return []
   const parts: string[] = []
   let depth = 0
   let current = ""
   for (const char of value) {
      if (char === "{") depth++
      if (char === "}") depth--
      if (char === "," && depth === 0) {
         parts.push(current.trim())
         current = ""
      } else current += char
   }
   parts.push(current.trim())
   return parts.filter((part) => part !== "")
}

function ruleMatches(patterns: string[], base: string, file: string): boolean {
   const rel = relative(base, file)
   if (rel === "" || rel.startsWith("..") || isAbsolute(rel)) return false
   return ignore().add(patterns).ignores(rel.split(sep).join("/"))
}

type Rule = { path: string; patterns?: string[] }

function rulesIn(dir: string, seen = new Set<string>()): Rule[] {
   if (!existsSync(dir) || seen.has(fileKey(dir))) return []
   seen.add(fileKey(dir))
   const rules: Rule[] = []
   for (const entry of readdirSync(dir)) {
      const path = join(dir, entry)
      let stats
      try {
         stats = statSync(path)
      } catch {
         continue
      }
      if (stats.isDirectory()) rules.push(...rulesIn(path, seen))
      else if (entry.endsWith(".md")) rules.push({ path, patterns: rulePatterns(readText(path)) })
   }
   return rules
}

type Worktree = { root: string; mainRoot: string }

// a linked worktree nested inside its main repo's checkout, as `claude -w` makes
function nestedWorktree(cwd: string): Worktree | undefined {
   for (const dir of ancestry(cwd).reverse()) {
      const dotGit = join(dir, ".git")
      if (!existsSync(dotGit)) continue
      if (!isFile(dotGit)) return undefined
      const gitdir = /^gitdir:\s*(.+)$/m.exec(readText(dotGit))?.[1].trim()
      if (!gitdir) return undefined
      const gitDir = resolve(dir, gitdir)
      const commondir = join(gitDir, "commondir")
      const commonGitDir = isFile(commondir) ? resolve(gitDir, readText(commondir).trim()) : gitDir
      const mainRoot = dirname(commonGitDir)
      if (fileKey(join(mainRoot, ".git")) !== fileKey(commonGitDir)) return undefined
      return inside(mainRoot, dir) && fileKey(mainRoot) !== fileKey(dir) ? { root: dir, mainRoot } : undefined
   }
   return undefined
}

export function steeringModel(profile: SteeringProfile, cwd: string, env: NodeJS.ProcessEnv = process.env): SteeringModel {
   const userDir = profile.userDir(env)
   const userSettings = readJson(join(userDir, "settings.json"))
   const excludes = [
      userSettings,
      readJson(join(cwd, ".claude", "settings.json")),
      readJson(join(cwd, ".claude", "settings.local.json")),
   ].flatMap((settings) => settings?.claudeMdExcludes ?? [])
   const excluded = (path: string) =>
      excludes.some((pattern: string) => matchesGlob(path, pattern) || matchesGlob(path.split(sep).join("/"), pattern))

   const agentsSetting = userSettings?.pluginConfigs
   const mode: AgentsMode =
      agentsSetting?.["cc-plugin-agents-md@builtin"]?.options?.instructionFiles ??
      agentsSetting?.["agents-md@builtin"]?.options?.instructionFiles ??
      profile.agents?.defaultMode ??
      "claude-md"
   const userMemory = profile.userNames.map((name) => fileKey(join(userDir, name)))
   const claudeNames = [...profile.names, ...profile.localNames]
   const claudeAtOrAbove = ancestry(cwd).some((dir) =>
      claudeNames.some((name) => isFile(join(dir, name)) && !userMemory.includes(fileKey(join(dir, name)))),
   )
   const agentsOn =
      profile.agents !== undefined &&
      (mode === "claude-md-and-agents-md" || (mode === "claude-md-or-agents-md" && !claudeAtOrAbove))

   // a file and everything it imports
   const closure = (path: string, allowExternal: boolean, seen: Set<string>, depth = 0): string[] => {
      const key = fileKey(path)
      const extension = extname(path).toLowerCase()
      if (seen.has(key) || !isFile(path) || excluded(resolve(path))) return []
      if (profile.imports && (depth >= profile.imports.maxDepth || (extension && !profile.imports.extensions.includes(extension))))
         return []
      seen.add(key)
      const imported = profile.imports
         ? importsOf(path, readText(path))
              .filter((target) => allowExternal || inside(cwd, target))
              .flatMap((target) => closure(target, allowExternal, seen, depth + 1))
         : []
      return [...imported, key]
   }

   // the first name that exists, or all of them
   const present = (dir: string, names: string[]) => {
      const paths = names.map((name) => join(dir, name)).filter(isFile)
      return profile.firstOnly ? paths.slice(0, 1) : paths
   }

   const launch = new Set<string>()
   const seen = new Set<string>()
   const load = (paths: string[], allowExternal: boolean) => {
      for (const path of paths) for (const key of closure(path, allowExternal, seen)) launch.add(key)
   }

   const managed = profile.managed?.[process.platform]
   if (managed) load([managed], true)
   if (mode !== "managed-only") {
      load(present(userDir, profile.userNames), true)
      if (profile.rulesDir)
         load(rulesIn(join(userDir, "rules")).filter((rule) => !rule.patterns).map((rule) => rule.path), true)

      const worktree = nestedWorktree(cwd)
      let shadowed: string | undefined
      if (worktree && profile.worktrees === "shadow-main-repo-file") {
         const own = present(worktree.root, profile.names)[0]
         if (own) shadowed = fileKey(join(worktree.mainRoot, own.slice(worktree.root.length + 1)))
      }
      for (const dir of ancestry(cwd)) {
         const mainRepoOnly =
            worktree !== undefined && inside(worktree.mainRoot, dir) && !inside(worktree.root, dir)
         const skipCheckedIn = mainRepoOnly && profile.worktrees === "skip-main-repo-files"
         if (!skipCheckedIn) {
            load(present(dir, profile.names).filter((path) => fileKey(path) !== shadowed), false)
            if (profile.rulesDir)
               load(rulesIn(join(dir, profile.rulesDir)).filter((rule) => !rule.patterns).map((rule) => rule.path), false)
         }
         load(present(dir, profile.localNames), false)
         if (agentsOn) load(present(dir, profile.agents!.launchNames), false)
      }
   }

   const onReadCache = new Map<string, string[]>()
   const onRead = (file: string): string[] => {
      const cacheKey = fileKey(file)
      if (!profile.onRead) return []
      if (onReadCache.has(cacheKey)) return onReadCache.get(cacheKey)!
      const loaded = new Set<string>()
      const add = (paths: string[]) => {
         for (const path of paths) for (const key of closure(path, false, new Set())) if (!launch.has(key)) loaded.add(key)
      }
      const matching = (rulesDir: string, base: string) =>
         rulesIn(rulesDir)
            .filter((rule) => rule.patterns && ruleMatches(rule.patterns, base, file))
            .map((rule) => rule.path)

      for (const dir of nestedDirs(cwd, file)) {
         const own = present(dir, claudeNames)
         add(own)
         if (profile.rulesDir) {
            const rules = rulesIn(join(dir, profile.rulesDir))
            add(rules.filter((rule) => !rule.patterns).map((rule) => rule.path))
            add(matching(join(dir, profile.rulesDir), dir))
         }
         if (agentsOn && (mode === "claude-md-and-agents-md" || own.length === 0))
            add(present(dir, profile.agents!.onReadNames))
      }
      if (profile.rulesDir) {
         for (const dir of ancestry(cwd)) add(matching(join(dir, profile.rulesDir), dir))
         add(matching(join(userDir, "rules"), cwd))
      }
      const result = [...loaded]
      onReadCache.set(cacheKey, result)
      return result
   }

   // reading a steering file in place loads it; a path-scoped rule loads on reads of other files
   const loadable = (file: string): boolean => {
      const key = fileKey(file)
      if (launch.has(key) || onRead(file).includes(key)) return true
      const posixPath = resolve(file).split(sep).join("/")
      return profile.onRead && profile.rulesDir !== undefined && posixPath.includes(`/${profile.rulesDir}/`)
   }

   return { launch, onRead, loadable }
}
