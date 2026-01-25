---
paths: **docs/sigil_lang/**/spec**
---

# Sigil Language Specification Format

Style: [Go Language Specification](https://go.dev/ref/spec)

## Core Principles

1. **Concise** - No fluff, no tutorials, just facts
2. **Declarative** - State what IS, not how to use it
3. **Technical** - Precise terminology, formal grammar

## File Structure

```markdown
# Section Title

One-line definition.

[Optional: Brief elaboration, 1-2 sentences max]

## Subsection

production_name = expression .

Description in short declarative sentences. Technical terms in _italics_ on first use. Syntax elements in `backticks`.

Constraints stated directly:
- X must be Y.
- Z may not contain W.

Valid examples:

valid_code()

Invalid examples:

invalid_code()  // error: reason
```

## Normative Keywords

| Keyword | Meaning |
|---------|---------|
| must | Absolute requirement |
| must not | Absolute prohibition |
| may | Optional |
| may not | Prohibited |

## Grammar (EBNF)

```
production_name = expression .
```

- `snake_case` production names
- `"keyword"` literal tokens
- `|` alternation, `[ ]` optional, `{ }` repetition, `( )` grouping
- `.` terminates productions

## Prose Rules

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

## Examples

```sigil
// Valid
example()

// Invalid - reason
bad()  // error: explanation
```

## Template Location

See `docs/sigil_lang/0.1-alpha/spec/_template.md` for new files.
