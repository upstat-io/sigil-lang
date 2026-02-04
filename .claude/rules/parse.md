---
paths:
  - "**/parse/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Last expression IS the value. `return` token exists only to emit helpful error.

# Parser

## Pre-Implementation
- Spec first: add grammar to `docs/ori_lang/0.1-alpha/spec/`
- Update `grammar.ebnf`
- Check disambiguation and context flags
- Create failing tests in `tests/spec/`

## Implementation
- Lexer: new tokens in `ori_lexer/`
- AST: add nodes to `ori_ir/`
- Parser: add parsing in `ori_parse/`
- Type checker + Evaluator updates

## Context Flags
- `NO_STRUCT_LIT` — prevent in `if` conditions
- `IN_PATTERN` — parsing pattern
- `IN_INDEX` — inside `[...]` (enables `#`)
- `IN_LOOP` — enables `break`/`continue`

## Lexer-Parser Boundary
- `>` always single token (never `>>`)
- Parser combines adjacent `>` in expression context
- Enables: `Result<Result<T, E>, E>`

## Progress Tracking
- `Progress::None` + error → try alternative
- `Progress::Made` + error → commit and sync

## Key Files
- `ori_lexer/src/lib.rs`: Tokens
- `context.rs`: ParseContext flags
- `grammar/`: Parsing
- `grammar.ebnf`: Unified grammar
