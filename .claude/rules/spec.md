---
paths: **/spec/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

# Ori Language Specification

Style: [Go Language Specification](https://go.dev/ref/spec)

**Sync rules in `.claude/rules/ori-lang.md`** — spec changes MUST sync with design docs, guide, module docs.

## This is a SPECIFICATION

| Specification | Design (`../design/`) |
|---------------|----------------------|
| Defines what IS valid Ori | Explains WHY |
| Normative, authoritative | Informative |
| Formal, precise | Tutorial tone |
| "An identifier is..." | "You can use identifiers to..." |

**Never use tutorial language. Never say "you" or "best practice".**

## Core Principles

- **Concise**: no fluff, no tutorials, just facts
- **Declarative**: state what IS, not how to use
- **Technical**: precise terminology, formal grammar

## Writing Style

**DO:**
- Short declarative sentences
- _Italics_ for technical terms (first use)
- `Backticks` for syntax
- Direct constraints: "X must be Y"

**DO NOT:**
- "you can...", "let's...", "we..."
- Rhetorical questions
- Motivation ("useful for...")
- Verbose explanations

## Normative Keywords

| Term | Meaning |
|------|---------|
| must | Absolute requirement |
| must not | Absolute prohibition |
| should | Recommendation |
| may | Optional |
| error | Compile-time failure |

## Grammar

Complete formal grammar in `grammar.ebnf` — single source of truth.

**Do not inline EBNF.** Reference instead:
```markdown
> **Grammar:** See [grammar.ebnf](...) § SECTION_NAME
```

### EBNF Conventions

- `snake_case` production names
- `"keyword"` literal tokens
- `|` alternation, `[ ]` optional, `{ }` repetition, `( )` grouping
- `.` terminates productions

## Section Structure

```markdown
# Major Section

Brief normative introduction.

> **Grammar:** See [grammar.ebnf](...) § SECTION_NAME

## Subsection

### Semantics
Normative definitions.

### Constraints
- It is an error if X.
- Y must satisfy Z.

### Examples
> **Note:** Informative.
```

## Cross-References

```markdown
See [Types](06-types.md).
See [Expressions § Operators](09-expressions.md#operators).
```

## Checklist

- Update `grammar.ebnf` if syntax changed
- Use formal language throughout
- Mark informative sections with `> **Note:**`
- SYNC: Update design docs, guide, modules

## Common Mistakes

- Tutorial language: "You can..." → "A program may..."
- Inline EBNF: use grammar.ebnf reference
- Unmarked informative content: use `> **Note:**`
- Missing sync: spec change without design doc update

## Template

See `docs/ori_lang/0.1-alpha/spec/_template.md`
