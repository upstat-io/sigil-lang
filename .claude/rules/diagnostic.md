---
paths: **diagnostic
---

# Diagnostics

## Error Codes

- **E0xxx**: Lexer (E0001-E0005)
- **E1xxx**: Parser (E1001-E1014)
- **E2xxx**: Type checker (E2001-E2018)
- **E3xxx**: Pattern (E3001-E3003)
- **E9xxx**: Internal (E9001-E9002)

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

## Key Files

| File | Purpose |
|------|---------|
| `error_code.rs` | Error code enum, phase ranges |
| `diagnostic.rs` | Diagnostic struct, builder, Label, Suggestion |
| `errors/mod.rs` | Embedded markdown docs, lazy HashMap |
