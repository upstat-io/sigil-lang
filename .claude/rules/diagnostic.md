---
paths:
  - "**/diagnostic/**"
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Diagnostics

## Error Codes

- **E0xxx**: Lexer (E0001-E0005)
- **E1xxx**: Parser (E1001-E1014)
- **E2xxx**: Type checker (E2001-E2018)
- **E3xxx**: Pattern (E3001-E3003)
- **E08xx**: Evaluator/Runtime (E0801-E0899)
- **E9xxx**: Internal (E9001-E9002)

New codes: increment within range, add doc in `errors/EXXX.md`.

## Diagnostic Structure

- `Diagnostic { code, severity, message, labels, notes, suggestions, structured_suggestions }`
- Builder: `Diagnostic::error(code).with_message().with_label().with_note().with_fix()`
- Applicability: `MachineApplicable` | `MaybeIncorrect` | `HasPlaceholders` | `Unspecified`

## Message Style

- Backticks for code: `` `variable` ``
- No periods in main message
- Imperative suggestions: "try using X" not "Did you mean X?"
- Verb phrase fixes: "Replace X with Y" not "the replacement"
- Three-part: problem → source context → actionable guidance

## Error Documentation (E2001.md)

- **Title**: `# EXXX: Error Name`
- **Sections**: Problem, Example, Causes (numbered), Solutions (with code), See Also

## Emitters

| Emitter | Output |
|---------|--------|
| `AriadneEmitter` | Rich terminal output with colors |
| `JsonEmitter` | Machine-readable JSON for tooling |
| `LspEmitter` | LSP-compatible diagnostics |

## Key Files

| File | Purpose |
|------|---------|
| `error_code.rs` | Error code enum, phase ranges |
| `diagnostic.rs` | Diagnostic struct, builder, Label, Suggestion |
| `errors/mod.rs` | Embedded markdown docs, lazy HashMap |
| `emitters/` | AriadneEmitter, JsonEmitter, LspEmitter |
| `queue.rs` | DiagnosticQueue for accumulation |
