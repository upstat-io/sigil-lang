---
path: **/docs/sigil_lang/**
---

# Sigil Documentation Synchronization Rules

When editing files in `docs/sigil_lang/`, follow these todos based on what you're changing.

## If file is changed in `design/`

- [ ] Synchronize change to corresponding `spec/` file (use formal, normative tone)
- [ ] Synchronize change to `/CLAUDE.md` if it affects syntax, types, or patterns
- [ ] Update `guide/` examples if user-facing behavior changed
- [ ] Fix any cross-references between design and spec
- [ ] Ask user: "Should I create a draft proposal in `docs/sigil_lang/proposals/drafts/` for this change to be applied to the compiler?"

## If file is changed in `spec/`

- [ ] Synchronize change to corresponding `design/` file (use explanatory tone)
- [ ] Synchronize change to `/CLAUDE.md` if it affects syntax, types, or patterns
- [ ] Update `guide/` examples to match new spec
- [ ] Update `modules/` docs if stdlib affected
- [ ] Fix any cross-references between spec and design
- [ ] Ask user: "Should I create a draft proposal in `docs/sigil_lang/proposals/drafts/` for this change to be applied to the compiler?"

## If file is changed in `guide/`

- [ ] Verify all examples are valid per current `spec/`
- [ ] If examples require spec changes, update `spec/` first
- [ ] Update `/CLAUDE.md` if new syntax patterns are demonstrated

## If file is changed in `modules/`

- [ ] Verify all type signatures match `spec/`
- [ ] Verify all examples are valid per current `spec/`
- [ ] Update `design/` if new stdlib rationale needed

## If `/CLAUDE.md` is changed

- [ ] Verify change is consistent with `spec/`
- [ ] Verify change is consistent with `design/`
- [ ] If CLAUDE.md introduces something not in spec/design, update those first

## If adding a new type

- [ ] Add formal definition to `spec/06-types.md`
- [ ] Add rationale to `design/03-type-system/`
- [ ] Add usage examples to `guide/`
- [ ] Update `modules/` if stdlib uses the type
- [ ] Update `/CLAUDE.md` Types section
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## If adding a new pattern

- [ ] Add formal definition to `spec/10-patterns.md`
- [ ] Add detailed explanation to `design/02-syntax/04-patterns-reference.md`
- [ ] Add tutorial examples to `guide/`
- [ ] Add to `design/appendices/D-pattern-quick-reference.md`
- [ ] Update `/CLAUDE.md` Patterns section
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## If changing syntax

- [ ] Update grammar productions in `spec/`
- [ ] Update `spec/03-lexical-elements.md` if tokens changed
- [ ] Update `design/02-syntax/` explanations
- [ ] Update `design/appendices/A-grammar-reference.md`
- [ ] Update ALL example code in ALL files to use new syntax
- [ ] Update `/CLAUDE.md` to reflect new syntax
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## If creating a new version

- [ ] Copy entire version directory: `cp -r 0.1-alpha 0.2-alpha`
- [ ] Update version references in all files
- [ ] Update root `docs/sigil_lang/README.md` to list new version

## Reference: Document Types

| Type | Location | Purpose | Tone |
|------|----------|---------|------|
| **Spec** | `spec/` | Define what IS valid Sigil | Formal, normative |
| **Design** | `design/` | Explain WHY decisions were made | Explanatory |
| **Guide** | `guide/` | Teach HOW to use Sigil | Tutorial |
| **Modules** | `modules/` | Document standard library | Reference |

## Reference: Cross-Reference Format

```markdown
// From spec to design
See [Design: Error Handling](../design/05-error-handling/index.md)

// From design to spec
See [Spec: Types](../spec/06-types.md)

// Within spec
See [Expressions](09-expressions.md)
```

## Never Do These

- Change spec without updating design
- Change design without updating spec
- Add examples that don't match the spec
- Leave broken cross-references
- Update docs without updating `/CLAUDE.md` when syntax/types/patterns change
