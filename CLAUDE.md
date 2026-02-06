**Ori is under construction.** Rust tooling (cargo, rustc) is trusted and stable. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT—all are being built from scratch. When something fails, investigate the Ori infrastructure first. Do not assume user code or tests are wrong; the bug is often in the compiler/tooling itself.

**Broken Window Policy**: Fix EVERY issue you encounter—no exceptions. Never say "this is pre-existing", "this is unrelated", or "outside the scope". If you see it, you own it. Add discovered issues to your todo list and fix them before completing your task. Leaving broken code because "it was already broken" is explicitly forbidden.

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

**NO WORKAROUNDS. NO HACKS. NO SHORTCUTS.**
- **Proper fixes only** — If a fix feels hacky, it IS hacky. Find the right solution.
- **When unsure, STOP and ASK** — Do not guess. Do not assume. Pause and ask the user for guidance.
- **Fact-check everything** — Verify behavior against the spec. Test your assumptions. Read the code you're modifying.
- **Consult reference repos** — Check `~/projects/reference_repos/lang_repos/` (Rust, Go, Zig, TypeScript, Gleam, Elm, Roc, Swift, Koka, Lean 4) for established patterns and idioms.
- **No "temporary" fixes** — There is no such thing. Today's temporary fix is tomorrow's permanent tech debt.
- **If you can't do it right, say so** — Communicate blockers rather than shipping bad code.

**TDD for bugs — NEVER fix without tests first**:
1. **STOP** — Do not jump to fixing. Resist the urge to immediately change code.
2. **Understand** — Consult the spec (`docs/ori_lang/0.1-alpha/spec/`), grammar, and design docs. Know the *intended* behavior.
3. **Reproduce with tests** — Write MULTIPLE tests (not just one):
   - The exact failing case that exposed the bug
   - Edge cases: boundaries, empty inputs, single elements, maximum values
   - Related variations: similar patterns that might also be affected
   - Regression guards: cases that currently work and must continue to work
4. **Verify tests fail** — All bug-reproducing tests MUST fail. If they pass, you misunderstand the bug or the spec.
5. **Fix the code** — Now implement the fix.
6. **Tests pass unchanged** — All tests must pass WITHOUT modifying them. If you need to change tests to pass, you either wrote wrong tests or made a wrong fix. Go back to step 2.

---

## Ori Language

**Ori**: Statically-typed **expression-based** language. HM inference, ARC memory, capability effects, mandatory tests. Targets LLVM/WASM. Compiler in Rust (Salsa-based).

**EXPRESSION-BASED — NO `return` KEYWORD**: Every block's value is its last expression. There is no `return` statement. Early exit uses `?` (propagate errors), `break` (exit loops), or `panic` (terminate). The `return` keyword is intentionally not part of Ori. Similar to: Rust (closest), Gleam, Roc, Ruby, Elixir, OCaml.

### Ori Syntax Reference

For Ori syntax, types, patterns, and prelude:
- **Auto-loaded** when editing `.ori` files (via `.claude/rules/ori-syntax.md`)
- **On-demand**: Use `/ori-syntax` skill
- **Manual**: Read `.claude/rules/ori-syntax.md`

**Spec is authoritative**: `docs/ori_lang/0.1-alpha/spec/` (`grammar.ebnf` for syntax, `operator-rules.md` for semantics)

### Design Pillars

1. **Expression-Based**: Everything is an expression; last expression is the block's value; no `return` keyword
2. **Mandatory Verification**: Functions need tests; contracts (`pre_check:`/`post_check:`)
3. **Dependency-Aware Integrity**: Tests in dep graph; changes propagate
4. **Explicit Effects**: Capabilities (`uses Http`); trivial mocking (`with Http = Mock in`)
5. **ARC-Safe**: No GC/borrow checker; capture by value; no shared mutable refs

---

## Compiler Coding Guidelines

**Architecture**: Crate deps: `oric` → `ori_types/eval` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic` (no upward); IO only in CLI (`oric`); no phase bleeding

**Memory**: Arena + ID (`ExprArena`+`ExprId`, not `Box<Expr>`); intern identifiers (`Name`, not `String`); newtypes for IDs; no `Arc` cloning in hot paths; `#[cold]` on error factories

**Salsa**: Query types derive `Clone, Eq, PartialEq, Hash, Debug`; no `Arc<Mutex<T>>`, fn pointers, or `dyn Trait`; deterministic (no random/time/IO); accumulate errors

**API Design**: >3-4 params → config struct; no boolean flags; RAII guards for context; return iterators not `Vec`; document public items

**Dispatch**: Enum for fixed sets (exhaustiveness, static dispatch); `dyn Trait` only for user-extensible; cost: `&dyn` < `Box<dyn>` < `Arc<dyn>`

**Diagnostics**: All errors have spans; imperative suggestions ("try using X"); verb phrase fixes ("Replace X with Y"); no `panic!` on user errors; accumulate

**Testing**: Verify behavior not implementation; tests based on spec, not current code; multiple test angles per feature (happy path, edge cases, error cases); inline < 200 lines; TDD is mandatory for bugs (see above)

**Performance**: O(n²) → O(n) or O(n log n); hash lookups not linear scans; no allocation in hot loops; iterators over indexing

**Style**: No `#[allow(clippy)]` without justification; functions < 50 lines (target < 30); no dead/commented code or banners; `//!`/`///` docs

**Tracing — ALWAYS USE FOR DEBUGGING**: `ORI_LOG` is your **first** debugging tool. Before `println!`, before reading code line-by-line, turn on tracing. Use `tracing` macros, not `println!`/`eprintln!`. Levels: `error` (never happen), `warn` (recoverable), `debug` (phases/queries), `trace` (per-expression). Targets by crate: `ori_types` (type checker), `ori_eval` (evaluator), `ori_llvm` (codegen), `oric` (Salsa queries). Use `#[tracing::instrument]` on public API functions. Salsa queries use manual `tracing::debug!()`. Setup: `compiler/oric/src/tracing_setup.rs`.

**Match Extraction**: No 20+ arm match in single file; group related arms; 3+ similar → extract helper

**Continuous Improvement**: Fix ALL issues in code you touch—dead code, unclear names, duplicated logic, style violations. "Pre-existing" and "unrelated" are not valid reasons to skip fixes. If you opened the file, you're responsible for its quality. Refactor when patterns emerge.

---

## Commands

**Primary**: `./test-all.sh`, `./clippy-all.sh`, `./fmt-all.sh`, `./build-all.sh` (includes LLVM)
**Tests**: `cargo t` (Rust), `cargo st` (Ori), `cargo st tests/spec/path/` (specific), `./llvm-test.sh`
**Build**: `cargo c`/`cl`/`b`/`fmt`, `./llvm-build.sh`, `./llvm-clippy.sh`
**LLVM/AOT**: `cargo bl` (debug), `cargo blr` (release) — builds oric + ori_rt with LLVM feature
**Tracing/Debugging** (USE FIRST — before println, before reading code line-by-line):
`ORI_LOG=debug ori check file.ori` | `ORI_LOG=ori_types=trace ORI_LOG_TREE=1 ori check file.ori` | `ORI_LOG=ori_eval=debug ori run file.ori` | `ORI_LOG=oric=debug ori check file.ori` (Salsa queries) | Falls back to `RUST_LOG`
**Always run `./test-all.sh` after compiler changes.**

> **Note**: AOT compilation (`ori build`) requires `libori_rt.a`. Use `cargo bl`/`blr` to build both the compiler and runtime library together.

## Key Paths

`compiler/oric/` — compiler | `docs/ori_lang/0.1-alpha/spec/` — **spec (authoritative)** | `spec/grammar.ebnf` — syntax | `spec/operator-rules.md` — operator semantics | `docs/ori_lang/proposals/` — proposals | `library/std/` — stdlib | `tests/spec/` — conformance | `compiler/oric/tests/phases/` — phase tests | `plans/roadmap/` — roadmap

## Reference Repos (`~/projects/reference_repos/lang_repos/`)

- **rust** — `rustc_errors/src/{lib,diagnostic,json}.rs`, `rustc_lint_defs/src/lib.rs`
- **golang** — `cmd/compile/internal/base/print.go`, `go/types/errors.go`, `internal/types/errors/codes.go`
- **typescript** — `compiler/{types.ts,diagnosticMessages.json}`, `services/{codeFixProvider,textChanges}.ts`
- **zig** — `src/{Compilation,Sema,Type,Value,InternPool,Zcu,main}.zig`
- **gleam** — `compiler-core/src/{error,diagnostic,warning,analyse,exhaustiveness}.rs`
- **elm** — `compiler/src/Reporting/{Error,Suggest,Doc}.hs`, `Error/{Type,Syntax}.hs`
- **roc** — `crates/reporting/src/{report,error/{type,canonicalize,parse}}.rs`
- **swift** — `lib/SILOptimizer/ARC/`, `lib/SIL/`, `lib/Sema/`, `include/swift/AST/Ownership.h`
- **koka** — `src/Type/{Infer,Operations,Unify}.hs`, `src/Core/{Borrowed,CheckFBIP}.hs`, `src/Compile/`
- **lean4** — `src/Lean/Compiler/IR/{RC,Borrow,ExpandResetReuse}.lean`, `src/Lean/Compiler/LCNF/`

## CLI

`ori run file.ori` | `ori check file.ori` | `ori check --no-test` | `ori check --strict` | `ori test` | `ori test --only-attached` | `ori fmt src/`

## Files & Tests

`.ori` source, `.test.ori` in `_test/` | Attached: `@test tests @target () -> void` (runs on target/caller changes) | Floating: `tests _` (runs via `ori test`) | Private: `::` prefix | Every function (except `@main`) requires tests

## Entry Points

`@main () -> void` | `() -> int` | `(args: [str]) -> void` | `(args: [str]) -> int` — `args` excludes program name
`@panic (info: PanicInfo) -> void` — optional handler; `print()` → stderr; first panic wins; re-panic = immediate termination
