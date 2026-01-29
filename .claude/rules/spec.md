---
paths: **spec**
---

# Ori Language Specification Format

Style: [Go Language Specification](https://go.dev/ref/spec)

**IMPORTANT: Synchronization rules are defined in `.claude/rules/ori-lang-docs.md`.**

Any spec change MUST be synchronized with design docs, guide, and module docs.

## This is a SPECIFICATION

| Specification (here) | Design (`../design/`) |
|---------------------|----------------------|
| Defines what IS valid Ori | Explains WHY decisions were made |
| Normative, authoritative | Informative, explanatory |
| Formal, precise language | Tutorial tone, best practices |
| "An identifier is..." | "You can use identifiers to..." |

**Never use tutorial language. Never say "you" or "best practice".**

## Core Principles

1. **Concise** - No fluff, no tutorials, just facts
2. **Declarative** - State what IS, not how to use it
3. **Technical** - Precise terminology, formal grammar

## Writing Style

### Do Use
```markdown
An identifier is a sequence of letters, digits, and underscores.

The type of a binary expression `a + b` is determined by...

It is a compile-time error if the operand types are incompatible.

A function declaration introduces a new binding in the current scope.
```

### Do Not Use
```markdown
You can use identifiers to name things.

When you write `a + b`, you get back...

Don't use incompatible types or you'll get an error.

Functions let you organize your code into reusable pieces.
```

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

## Normative Keywords

| Term | Meaning |
|------|---------|
| must | Absolute requirement |
| must not | Absolute prohibition |
| shall | Same as must |
| should | Recommendation |
| may | Optional |
| may not | Prohibited |
| error | Compile-time failure |
| undefined | Implementation-defined |

## Grammar

The complete formal grammar is in [grammar.ebnf](https://ori-lang.com/docs/compiler-design/04-parser#grammar). This is the **single source of truth** for all syntax.

**Do not inline EBNF in spec files.** Instead, reference the grammar file:

```markdown
> **Grammar:** See [grammar.ebnf](https://ori-lang.com/docs/compiler-design/04-parser#grammar) § SECTION_NAME
```

Where `SECTION_NAME` matches the comment headers in grammar.ebnf (e.g., LEXICAL GRAMMAR, TYPES, DECLARATIONS, EXPRESSIONS, PATTERNS).

### EBNF Conventions

```
production_name = expression .
```

- `snake_case` production names
- `"keyword"` literal tokens
- `|` alternation, `[ ]` optional, `{ }` repetition, `( )` grouping
- `.` terminates productions

## Section Structure

```markdown
# Major Section

Brief normative introduction.

> **Grammar:** See [grammar.ebnf](https://ori-lang.com/docs/compiler-design/04-parser#grammar) § SECTION_NAME

## Subsection

### Semantics

Normative definitions here.

### Constraints

- It is an error if X.
- Y must satisfy Z.

### Examples

> **Note:** The following examples are informative.

\`\`\`ori
// example code
\`\`\`
```

## Examples

```ori
// Valid
example()

// Invalid - reason
bad()  // error: explanation
```

## Cross-References

```markdown
See [Types](06-types.md).
See [Expressions § Operators](09-expressions.md#operators).
See [Design: Error Handling](../design/05-error-handling/index.md).
```

## Checklist for Spec Changes

- [ ] Update [grammar.ebnf](https://ori-lang.com/docs/compiler-design/04-parser#grammar) if syntax changed
- [ ] Use formal language throughout
- [ ] Mark informative sections with `> **Note:**`
- [ ] Update cross-references within spec
- [ ] **SYNC: Update corresponding design docs**
- [ ] **SYNC: Update guide if user-facing**
- [ ] **SYNC: Update modules if stdlib affected**

## Common Mistakes

1. **Tutorial language**: "You can..." → "A program may..."
2. **Inline EBNF**: Use grammar.ebnf reference instead
3. **Unmarked informative content**: Always use `> **Note:**`
4. **Forgetting sync**: Spec change without design doc update

## Template Location

See `docs/ori_lang/0.1-alpha/spec/_template.md` for new files.
