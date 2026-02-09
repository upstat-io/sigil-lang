---
paths:
  - "**/compiler/**"
---

# Implementation Hygiene Rules

Extracted from reference compilers: Rust (`rustc`), Zig (`Sema/Parse/Tokenizer`), Go (`go/scanner/parser`), Gleam (`compiler-core`), Swift (`SILOptimizer/ARC`), Lean 4 (`Compiler/IR`), Koka (`Type/Core`).

**Implementation hygiene is NOT architecture** (design decisions are made) **and NOT code hygiene** (surface style). It's about whether the implementation faithfully and cleanly realizes the architecture — tight joints, correct flow, no leaks.

## Phase Boundary Discipline

- **One-way data flow**: Data flows downstream only. Later phases never call back into earlier phases.
- **No circular imports**: Phase crates/modules must not import from downstream. `ori_lexer` never imports `ori_parse`.
- **Minimal boundary types**: Only pass what the next phase needs. Tokens: `(tag, span)`, not `(tag, span, source_slice, metadata)`.
- **Clean ownership transfer**: Move at boundaries, borrow within phases. No unnecessary `.clone()` at phase transitions.
- **No phase bleeding**: Lexer doesn't parse, parser doesn't type-check, type checker doesn't codegen. Each phase does exactly its job.
- **Phase purity enforcement**: A phase's output depends only on its input. No global mutable state, no side channels.

## Data Flow

- **Zero-copy where possible**: Spans reference source by position, not by owned slice. Tokens carry `(tag, len)` or `(tag, start, end)`, not string copies.
- **Arena per phase**: Temporary allocations freed when phase completes. No leakage to next phase.
- **Interned values via opaque indices**: Cross boundaries with `Name`, `ExprId`, `TypeId` — never raw `u32` or direct pointers to interned data.
- **No allocation in hot token paths**: Lexer→parser boundary is the hottest path. No `String::from()`, no `Vec::new()`, no `Box::new()` per token.
- **Source text borrowed**: Parser borrows source `&str`; only the final AST or error messages may need owned copies.

## Error Handling at Boundaries

- **Accumulate, don't bail**: Each phase collects all errors in one pass. User sees every problem, not just the first.
- **Phase-scoped error types**: Lexer errors ≠ parse errors ≠ type errors. Each phase defines errors relevant to its work.
- **Upstream errors propagated**: Parser must handle/propagate lexer errors, not swallow them. Earlier phase errors take priority.
- **Errors carry spans**: Every error includes source position. Errors without location are bugs.
- **Recovery is explicit**: Use enum state (`Recovery::Allowed | Forbidden`), not implicit boolean flags.

## Type Discipline at Boundaries

- **Separate raw vs cooked types**: Raw lexer output (`RawTag`) ≠ parser-ready tokens (`TokenKind`). Each boundary has its own type vocabulary.
- **Newtypes for all IDs**: `ExprId`, `TypeId`, `TokenIndex` — not raw `u32`. Prevents cross-boundary ID confusion.
- **Generic phase parameters**: Use `Module<Info, Defs>` pattern — same structure, different type parameters for untyped vs typed phases.
- **Metadata separated from data**: Comments, formatting info, whitespace live in a sidecar (`ModuleExtra`), not interleaved with AST nodes.
- **No phase state in output types**: AST nodes carry syntactic structure + spans. No parser cursor, no lookahead buffer, no inference state.

## Pass Composition

- **Each pass is IR → IR**: Takes input IR, produces output IR. No hidden inputs from global state.
- **Explicit pass ordering**: Dependencies between passes are documented and enforced, not implicit.
- **No shared mutable state between passes**: Each pass owns its working data. Inter-pass communication is via the IR itself.
- **Boundary validation**: Assert invariants before crossing to next phase (e.g., all tokens consumed, all types resolved).
- **`#[cold]` on error paths**: Error handling code doesn't pollute hot-path instruction cache.

## Phase-Specific Purity

**Lexer**: Stateless scanning. Produces structural facts (`tag`, `len`). Does NOT judge keywords, resolve names, or track nesting context beyond what's needed for tokenization.

**Parser**: Syntax only. Builds AST from tokens. Does NOT resolve names, check types, or validate semantics. Grammar-driven: each parse function corresponds to a grammar rule.

**Type Checker**: Consumes AST, produces typed IR. Does NOT re-parse, does not codegen. Errors accumulated via diagnostic infrastructure.

**Optimization Passes**: Each pass reads IR, produces transformed IR. No pass reaches into another pass's internal state. Loop/branch analysis is pass-local.
