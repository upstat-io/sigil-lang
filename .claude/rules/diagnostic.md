---
paths:
  - "**/diagnostic/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Diagnostics

## Error Codes
- **E0xxx**: Lexer
- **E1xxx**: Parser
- **E2xxx**: Type checker
- **E3xxx**: Pattern
- **E08xx**: Evaluator
- **E9xxx**: Internal

New codes: increment within range, add doc in `errors/EXXX.md`.

## Diagnostic Structure
- `Diagnostic { code, severity, message, labels, notes, suggestions }`
- Builder: `Diagnostic::error(code).with_message().with_label().with_fix()`
- Applicability: `MachineApplicable` | `MaybeIncorrect` | `HasPlaceholders`

## Message Style
- Backticks for code: `` `variable` ``
- No periods in main message
- Imperative: "try using X"
- Three-part: problem → context → guidance

## Emitters
- `AriadneEmitter`: Terminal
- `JsonEmitter`: JSON
- `LspEmitter`: LSP

## Key Files
- `error_code.rs`: Error codes
- `diagnostic.rs`: Builder
- `emitters/`: Output formats
- `queue.rs`: Accumulation
