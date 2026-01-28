---
paths: **parse**
---

# Parser Development Guidelines

When making changes to the Ori parser (`compiler/ori_parse/`), follow these checklists to ensure consistency and avoid regressions.

## Pre-Implementation Checklist

Before implementing any new syntax:

- [ ] **Spec first:** Add formal grammar to `docs/ori_lang/0.1-alpha/spec/`
- [ ] **Update grammar.ebnf:** Add production to `docs/ori_lang/0.1-alpha/spec/grammar.ebnf`
- [ ] **Check disambiguation:** Will this conflict with existing syntax?
- [ ] **Check context:** Which contexts should allow/disallow this? (see `ParseContext` flags in `compiler/ori_parse/src/context.rs`)
- [ ] **Add skeleton tests:** Create failing tests for all cases in `tests/spec/`

## Implementation Checklist

- [ ] **Lexer changes:** Any new tokens needed? (`compiler/ori_lexer/src/lib.rs`)
- [ ] **AST changes:** Add node types to `compiler/ori_ir/`
- [ ] **Parser changes:** Add parsing in `compiler/ori_parse/`
- [ ] **Context flags:** Any new context requirements? (e.g., `IN_PATTERN`, `NO_STRUCT_LIT`)
- [ ] **Type checker:** Add to `compiler/ori_typeck/`
- [ ] **Evaluator:** Add to `compiler/ori_eval/`

## Post-Implementation Checklist

- [ ] **Tests pass:** All skeleton tests converted to passing
- [ ] **Matrix updated:** New syntax added to compositional tests (`compiler/ori_parse/src/compositional_tests.rs`)
- [ ] **CLAUDE.md updated:** Quick reference reflects new syntax
- [ ] **Examples work:** Real-world usage tested
- [ ] **Error messages:** Good errors for misuse
- [ ] **Run full test suite:** `./test-all` passes

## Key Files

| Path | Purpose |
|------|---------|
| `compiler/ori_lexer/src/lib.rs` | Lexer tokens |
| `compiler/ori_parse/src/context.rs` | ParseContext flags |
| `compiler/ori_parse/src/grammar/` | Parsing implementations |
| `compiler/ori_parse/src/compositional_tests.rs` | Type/pattern matrix tests |
| `docs/ori_lang/0.1-alpha/spec/grammar.ebnf` | Unified grammar |
| `plans/parser_v2/PLAN.md` | Full parser improvement plan |

## Important Patterns

### Lexer-Parser Boundary
The lexer produces minimal tokens. Notably, `>` is always a single token (never `>>` or `>=`). The parser combines adjacent `>` tokens in expression context for shift operators. This enables parsing nested generics like `Result<Result<T, E>, E>`.

### Context Flags
Use `ParseContext` to control parsing behavior:
- `NO_STRUCT_LIT` — prevent struct literals in `if` conditions
- `IN_PATTERN` — parsing a pattern (enables pattern-specific syntax)
- `IN_INDEX` — inside `[...]` brackets (enables `#` length symbol)
- `IN_LOOP` — inside loop (enables `break`/`continue`)

### Progress Tracking
Use `ParseResult<T>` from `compiler/ori_parse/src/progress.rs` for parsing entry points. This enables smarter error recovery:
- `Progress::None` + error → try alternative
- `Progress::Made` + error → commit and synchronize

