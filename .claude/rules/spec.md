---
paths:
  - "**/spec/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. This is one system: every piece must fit for any piece to work. Fix every issue you encounter — no "unrelated", no "out of scope", no "pre-existing." If it's broken, research why and fix it.

**Expression-based — NO `return`**: Last expression IS the value. Exit via `?`/`break`/`panic`. Never document `return`.

# Ori Language Specification

Style: [Go Language Specification](https://go.dev/ref/spec). Sync rules in `.claude/rules/ori-lang.md`.

## Spec vs Design
- Specification: What IS valid Ori (normative, formal)
- Design (`../design/`): Explains WHY (tutorial tone)

**Never tutorial language. Never "you" or "best practice".**

## Writing Style
- **DO**: Declarative sentences, _italics_ terms, `backticks` syntax, "X must be Y"
- **DON'T**: "you can", rhetorical questions, motivation, verbose

## Normative Keywords
- `must`: Absolute requirement
- `must not`: Absolute prohibition
- `should`: Recommendation
- `may`: Optional
- `error`: Compile-time failure

## Grammar & Operator Rules
- `grammar.ebnf` — syntax (EBNF)
- `operator-rules.md` — semantics

**Reference, don't inline:**
```markdown
> **Grammar:** See [grammar.ebnf](...) § SECTION_NAME
> **Rules:** See [operator-rules.md](...) § OPERATOR_NAME
```

## EBNF Conventions
`snake_case` names | `"keyword"` tokens | `|` alt | `[ ]` opt | `{ }` repeat | `.` terminates

## Checklist
- Update `grammar.ebnf` if syntax changed
- Update `operator-rules.md` if operator changed
- Mark informative: `> **Note:**`
- SYNC: design docs, guide, modules

## Template
See `docs/ori_lang/0.1-alpha/spec/_template.md`
