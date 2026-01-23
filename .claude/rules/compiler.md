---
path: compiler/**
---

# Compiler Development

When working on the compiler, the source of truth for Sigil language design and specification is:

- **Specification**: `docs/sigil_lang/0.1-alpha/spec/` — formal language definition (grammar, semantics, behavior)
- **Design**: `docs/sigil_lang/0.1-alpha/design/` — rationale and detailed explanations for language decisions

Always consult these docs when:
- Implementing new language features
- Fixing parser/lexer/type-checker behavior
- Making decisions about language semantics
- Resolving ambiguities in how the language should work

If the compiler behavior differs from the spec, the spec is correct and the compiler needs to be fixed.
