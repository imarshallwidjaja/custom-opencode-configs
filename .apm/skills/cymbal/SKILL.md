---
name: cymbal
description: Use when navigating existing code with the cymbal CLI: locating symbols, tracing callers or callees, finding implementations, scoping change impact, mapping imports, or orienting in an unfamiliar repo before targeted reads.
---

# Cymbal Skill

## Rule
If the task touches existing code, **start with cymbal**. Do not start with
`rg`, `grep`, `find`, or whole-file `Read` when the user named a symbol, you
need dependency flow, or the file is large or unfamiliar.

## Default Investigation Loop
```
search  ->  investigate / context  ->  impact / trace / refs / impls  ->  show / outline
                                                                              |
                                                                              \- then targeted reads or rg
```

1. **Find it** - `cymbal search <query>` (add `--exact`, `--kind`, `--lang`, `--path`).
2. **Understand it** - `cymbal investigate <symbol>` (kind-adaptive: function -> source + callers + shallow impact; type -> source + members + references). Use `cymbal context <symbol>` only when you specifically want source + callers + imports bundled.
3. **Trace flow** - `cymbal impact` (upward), `cymbal trace` (downward), `cymbal refs` (direct uses), `cymbal impls` (who implements this).
4. **Read** - `cymbal show <symbol>` or `cymbal outline <file>` before `Read` or `rg`.

## Goal -> Command

| I want to... | Command |
|---|---|
| Find a symbol or text | `cymbal search <q>` (symbols) / `--text` (grep, delegates to rg) |
| Get the right shape of context for any kind of symbol | `cymbal investigate <symbol>` |
| Read source + type refs + callers + imports together | `cymbal context <symbol>` |
| Read source by symbol or file range | `cymbal show <symbol \| file[:L1-L2]>` |
| List symbols in a file | `cymbal outline <file>` (`-s` signatures, `--names` for piping) |
| Find direct references | `cymbal refs <symbol>` |
| See who depends on a symbol transitively | `cymbal impact <symbol>` (add `--graph` for blast radius) |
| See what a symbol calls | `cymbal trace <symbol>` (add `--graph` for topology) |
| Find types that implement an interface | `cymbal impls <symbol>` (add `--graph` for conformance tree) |
| See git diff for a symbol | `cymbal diff <symbol> [base]` (add `--stat`) |
| Find files importing a file/package | `cymbal importers <file\|pkg>` (add `--graph` for fan-in tree) |
| Get a map of the repo | `cymbal structure` |
| List file tree / stats / indexed repos | `cymbal ls` / `--stats` / `--repos` |

Every command supports `--json`. cymbal resolves the right DB automatically per
repo; do not start by running `cymbal index` manually during normal use because
queries auto-build and refresh the index.

## Command Details

### `search` - starting point
```
cymbal search OpenStore
cymbal search PatchMulti MultiEdit EditTool PatchTool
cymbal search parse --kind function --lang go
cymbal search "TODO" --text                              # full-text grep (uses rg)
cymbal search --text 'os\.WriteFile\(' tools/file.go     # rg-style path operand
cymbal search Handler --path 'internal/**' --exclude '**/*_test.go'
```
Ranked exact > prefix > fuzzy. Trust the first result - bench shows 100%
canonical ranking at rank 1 across the corpus.

### `investigate` - one call, right-shaped answer
```
cymbal investigate OpenStore
cymbal investigate config.go:Config       # file hint
cymbal investigate auth.Middleware        # parent/package hint
cymbal investigate Foo Bar Baz            # batch
```
Ambiguous names auto-resolve and list alternatives in `also` or `matches`. Use
this before `show`, `refs`, or `context` on unfamiliar symbols.

### `context` - bundled read
```
cymbal context OpenStore
cymbal context ParseFile --callers 10
```
`--callers` is the only knob (default 20). Use when you already know the
symbol matters and want one payload. Do not call both `investigate` and
`context` on the same symbol; pick one.

### `show` - read source
```
cymbal show ParseFile
cymbal show internal/index/store.go
cymbal show internal/index/store.go:80-120
cymbal show Foo Bar Baz
cymbal outline big.go -s --names | cymbal show --stdin
cymbal show Handler --all
cymbal show Foo --path 'internal/**' --exclude '**/*_test.go'
```
Supports `-C` context lines, `--path`, `--exclude`, `--all`, and `--stdin`.

### `outline` - file map
```
cymbal outline internal/index/store.go
cymbal outline internal/index/store.go --signatures
cymbal outline internal/index/store.go -s --names
```
Read this before opening large or unfamiliar files. The `--names` form is the
engine for batch mode in `show`, `refs`, `trace`, and `impact`.

### `refs` - direct references
```
cymbal refs ParseFile
cymbal refs ParseFile --file internal/
cymbal refs ParseFile --importers
cymbal refs ParseFile --impact
cymbal refs Foo Bar Baz
cymbal refs Foo --path 'cmd/**' --exclude '**/testdata/**'
```
`--depth` is capped at 3. This is best-effort AST name matching, not full
semantic analysis.

### `impact` - upward, transitive
```
cymbal impact handleRegister
cymbal impact handleRegister -D 3 -C 2
cymbal impact handleRegister --graph
cymbal impact Save Load Delete
cymbal outline store.go -s --names | cymbal impact --stdin
```

### `trace` - downward call chain
```
cymbal trace handleRegister
cymbal trace handleRegister --depth 5
cymbal trace handleRegister --graph
cymbal trace handleRegister --kinds call,use
cymbal outline svc.go -s --names | cymbal trace --stdin
```

### `impls` - who implements, extends, or conforms
```
cymbal impls Handler
```
Externally defined targets come back with `resolved=false`.

### `--graph` - visual topology
```
cymbal trace handleRegister --graph
cymbal impact handleRegister --graph
cymbal importers internal/index --graph
cymbal impls Handler --graph
cymbal trace handleRegister --graph-format json
```
Use graph mode when you need a high-level relationship map: fan-in, fan-out,
inheritance or conformance, or a quick orientation pass. Stay with the normal
text or JSON output when you need exact call sites, source lines, or detail
you will edit against. Defaults: Mermaid on a TTY, JSON when piped. Use
`--graph-limit` to cap dense graphs. `impact --graph` defaults to depth 1
unless you explicitly pass `--depth`. `--include-unresolved` is useful when
external relationships matter.

### `diff` - git diff scoped to a symbol
```
cymbal diff ParseFile
cymbal diff ParseFile main
cymbal diff --stat ParseFile
```

### `structure` / `ls` / `importers`
```
cymbal structure
cymbal ls --stats
cymbal ls --repos
cymbal importers internal/index
```

## Path Filtering
`search`, `show`, and `refs` accept repeatable `--path` and `--exclude` globs.
Compose them with `--kind` or `--lang`:
```
cymbal search Handler --lang go --path 'internal/**' --exclude '**/*_test.go'
cymbal refs OpenStore --path 'cmd/**'
```
On large repos this is the difference between useful and useless output.
(`context`, `investigate`, `trace`, `impact`, and `impls` do not take `--path`;
filter at the consumer step instead.)

## JSON Mode
`--json` works on every command. Look for:
- `also` or `matches` - alternate resolutions when a name is ambiguous.
- `ambiguous: true` - cymbal picked one; `also` lists the rest.
- `hit_symbols` - in batch mode (`refs`, `impact`, `trace`), which input brought each result in.
- `resolved: false` - in `impls`, the target is external.

## Pivot Rule
If one or two searches miss, stop searching synonyms. Pivot to implementation
seams instead:

> spec · registry · bundle · runtime · policy · session · state · dispatch · config · store · manifest · descriptor · provider · handler

Run `cymbal structure` to surface the actual entry points and hotspots, then
`investigate` the seam symbols you find.

## Stop Rules
- Do not run both `investigate` and `context` on the same symbol.
- Do not retry searches with synonyms more than twice; pivot.
- Do not default to `--graph` when you need precise call-site text or source lines.
- Do not `Read` a large file right after `search`; `outline` it first, then `show` the slice you need.
- Do not paginate through `refs` or `impact` output when `--limit` or `--path` would narrow it.
- Do not chain `investigate` -> `context` -> `show` on the same symbol.

## Anti-Patterns
1. `rg` or `grep` for a symbol name cymbal can resolve directly.
2. `Read` on a file larger than 500 lines without `outline` first.
3. Calling `show` before `investigate` on an unfamiliar symbol.
4. Treating `refs` as semantic "find all callers" when it is AST name matching.
5. Retrying on ambiguity errors instead of reading `also` or `matches`.
6. Running `cymbal index` before every query.
7. Hand-listing batch inputs when `outline -s --names | <cmd> --stdin` would work.

## Real Constraints
- `refs`, `impact`, and `trace` are AST name matching. Cross-package name collisions inflate results; narrow with `--path` or `--file`.
- `impls` returns `resolved=false` for externally defined interfaces.
- TypeScript and other non-Go languages may have incomplete signature data.
- Imports are resolved best-effort per language; cross-language edges are not modeled.
- `search --text` delegates to `rg`; it does not use the symbol index.

## When to Use What

1. "I just cloned this repo, where do I start?"
   -> `cymbal structure`, then `cymbal ls --stats`

2. "What is this function, class, or type?"
   -> `cymbal investigate <symbol>`

3. "What happens when X runs?"
   -> `cymbal trace <symbol>`

4. "If I change X, what breaks?"
   -> `cymbal impact <symbol>`

5. "Where is X defined?"
   -> `cymbal search <name>`, then `cymbal show <symbol>`

6. "What's in this file?"
   -> `cymbal outline <file>`, then `cymbal show <file:L1-L2>`

7. "Find all usages of X"
   -> `cymbal refs <symbol>`

8. "Who implements this interface?"
   -> `cymbal impls <symbol>`

9. "What changed in this symbol?"
   -> `cymbal diff <symbol> [base]`

## Why this works
Against the maintained corpus (gin, fastapi, kubectl, vite, ripgrep, jq, guava):
- 100% canonical at rank 1 on the hard-mode ranking suite.
- 85/85 (100%) accuracy across search, show, refs, and investigate.
- 84-100% token savings vs ripgrep on the same queries.

## Outcome
Start with cymbal. Pivot on misses. Trust the first rank. Read last.
