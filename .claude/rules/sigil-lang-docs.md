---
path: docs/sigil_lang/**
---

# AI Guidance for Sigil Language Documentation

## CRITICAL: Keep Everything in Sync

**All documentation within a version MUST be kept synchronized.**

When making changes to ANY file in a version directory, you MUST update ALL related files:

```
docs/sigil_lang/
└── 0.1-alpha/           # Everything in here versions together
    ├── spec/            # Formal specification (normative)
    ├── design/          # Design rationale (informative)
    ├── guide/           # User guide (tutorial)
    └── modules/         # Standard library docs
```

### Synchronization Rules

1. **Spec changes require design updates** — If the spec changes, update corresponding design docs
2. **Design changes may require spec updates** — If design docs describe new features, spec must define them
3. **Guide must match spec** — User guide examples must be valid per the spec
4. **Module docs must match spec** — Standard library docs must use correct syntax/types

### Before ANY Change, Ask:

- "Does this change affect the spec?" → Update spec files
- "Does this change affect design rationale?" → Update design files
- "Does this change affect user examples?" → Update guide files
- "Does this change affect stdlib docs?" → Update module files
- "Do cross-references need updating?" → Fix all links

## Version Structure

```
docs/sigil_lang/
├── README.md            # Documentation overview
└── {version}/           # e.g., 0.1-alpha, 0.2-beta, 1.0
    ├── spec/            # Language specification
    │   ├── README.md    # Spec organization
    │   ├── CLAUDE.md    # Spec-specific AI guidance
    │   ├── index.md     # Spec table of contents
    │   └── *.md         # Spec sections
    ├── design/          # Design documentation
    │   ├── 00-index.md  # Design table of contents
    │   └── */           # Design sections
    ├── guide/           # User guide
    └── modules/         # Standard library documentation
        └── std/         # std module docs
```

## Version Semantics

| Version | Meaning |
|---------|---------|
| `X.Y-alpha` | Unstable, expect breaking changes |
| `X.Y-beta` | Feature-complete, stabilizing |
| `X.Y-rc` | Release candidate |
| `X.Y` | Stable release |

## Document Types

| Type | Location | Purpose | Tone |
|------|----------|---------|------|
| **Spec** | `spec/` | Define what IS valid Sigil | Formal, normative |
| **Design** | `design/` | Explain WHY decisions were made | Explanatory |
| **Guide** | `guide/` | Teach HOW to use Sigil | Tutorial |
| **Modules** | `modules/` | Document standard library | Reference |

## When Creating New Versions

1. Copy entire version directory: `cp -r 0.1-alpha 0.2-alpha`
2. Update version references in all files
3. Make changes to new version
4. Update root README.md to list new version

## Cross-Reference Format

Within a version, use relative paths:

```markdown
// From spec to design
See [Design: Error Handling](../design/05-error-handling/index.md)

// From design to spec
See [Spec: Types](../spec/06-types.md)

// Within spec
See [Expressions](09-expressions.md)
```

## Checklist for ANY Documentation Change

- [ ] Identify all affected document types (spec/design/guide/modules)
- [ ] Update spec if syntax or semantics changed
- [ ] Update design if rationale changed
- [ ] Update guide if user-facing behavior changed
- [ ] Update modules if stdlib affected
- [ ] Fix all cross-references
- [ ] Verify version consistency

## Common Synchronization Scenarios

### Adding a New Type

1. `spec/06-types.md` — Add formal type definition
2. `design/03-type-system/*.md` — Add rationale if needed
3. `guide/` — Add usage examples
4. `modules/` — Update if stdlib uses the type

### Adding a New Pattern

1. `spec/10-patterns.md` — Add formal pattern definition
2. `design/02-syntax/04-patterns-reference.md` — Add detailed explanation
3. `guide/` — Add tutorial examples
4. `design/appendices/D-pattern-quick-reference.md` — Add to quick ref

### Changing Syntax

1. `spec/` — Update grammar productions
2. `spec/03-lexical-elements.md` — Update if tokens changed
3. `design/02-syntax/` — Update syntax explanations
4. `design/appendices/A-grammar-reference.md` — Update grammar summary
5. ALL example code in ALL files — Must use new syntax

## NEVER Do These

- Change spec without checking design docs
- Change design without checking spec
- Add examples that don't compile
- Leave broken cross-references
- Forget to update the version's index files
- Mix content from different versions
