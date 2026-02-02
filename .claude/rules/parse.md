---
paths: **/parse/**
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Parser Development

## Pre-Implementation

- **Spec first**: add grammar to `docs/ori_lang/0.1-alpha/spec/`
- **Update grammar.ebnf**: add production
- **Check disambiguation**: conflict with existing syntax?
- **Check context**: which contexts allow/disallow? (see `ParseContext`)
- **Skeleton tests**: create failing tests in `tests/spec/`

## Implementation

- **Lexer**: new tokens? (`ori_lexer/src/lib.rs`)
- **AST**: add nodes to `ori_ir/`
- **Parser**: add parsing in `ori_parse/`
- **Context flags**: new requirements? (`IN_PATTERN`, `NO_STRUCT_LIT`)
- **Type checker**: add to `ori_typeck/`
- **Evaluator**: add to `ori_eval/`

## Post-Implementation

- All skeleton tests pass
- Matrix updated (`compositional_tests.rs`)
- CLAUDE.md reflects new syntax
- Error messages for misuse
- `./test-all` passes

## Key Files

| Path | Purpose |
|------|---------|
| `ori_lexer/src/lib.rs` | Lexer tokens |
| `ori_parse/src/context.rs` | ParseContext flags |
| `ori_parse/src/grammar/` | Parsing implementations |
| `ori_parse/src/compositional_tests.rs` | Type/pattern matrix |
| `docs/ori_lang/0.1-alpha/spec/grammar.ebnf` | Unified grammar |

## Lexer-Parser Boundary

- Lexer produces minimal tokens
- `>` always single token (never `>>` or `>=`)
- Parser combines adjacent `>` in expression context
- Enables: `Result<Result<T, E>, E>`

## Context Flags

- `NO_STRUCT_LIT` — prevent struct literals in `if` conditions
- `IN_PATTERN` — parsing a pattern
- `IN_INDEX` — inside `[...]` (enables `#`)
- `IN_LOOP` — inside loop (enables `break`/`continue`)

## Progress Tracking

`ParseResult<T>` from `progress.rs`:
- `Progress::None` + error → try alternative
- `Progress::Made` + error → commit and synchronize

## Coding Guidelines

- Accumulate errors: never bail early; always produce AST
- All errors have spans
- Imperative suggestions: "try using X"
- Three-part messages: problem → context → guidance
- No `panic!` on user input
- Deterministic: same input → same AST and errors
