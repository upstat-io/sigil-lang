# Sigil Documentation Rules

When editing files in `docs/sigil_lang/`, follow these guidelines.

**Note:** Design docs have been archived to `archived-design/`. Do not update them.

## If file is changed in `spec/`

- [ ] Synchronize change to `/CLAUDE.md` if it affects syntax, types, or patterns
- [ ] Update `guide/` examples to match new spec (if guide exists)
- [ ] Update `modules/` docs if stdlib affected
- [ ] Ask user: "Should I create a draft proposal in `docs/sigil_lang/proposals/drafts/` for this change to be applied to the compiler?"

## If `/CLAUDE.md` is changed

- [ ] Verify change is consistent with `spec/`
- [ ] If CLAUDE.md introduces something not in spec, update spec first

## If adding a new type

- [ ] Add formal definition to `spec/06-types.md`
- [ ] Update `/CLAUDE.md` Types section
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## If adding a new pattern

- [ ] Add formal definition to `spec/10-patterns.md`
- [ ] Update `/CLAUDE.md` Patterns section
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## If changing syntax

- [ ] Update grammar productions in `spec/`
- [ ] Update `spec/03-lexical-elements.md` if tokens changed
- [ ] Update ALL example code in spec to use new syntax
- [ ] Update `/CLAUDE.md` to reflect new syntax
- [ ] Ask user: "Should I create a draft proposal for compiler implementation?"

## Reference: Document Types

| Type | Location | Purpose | Tone |
|------|----------|---------|------|
| **Spec** | `spec/` | Define what IS valid Sigil | Formal, normative |
| **Proposals** | `proposals/` | Capture decisions and rationale | Explanatory |

## Never Do These

- Add examples that don't match the spec
- Update docs without updating `/CLAUDE.md` when syntax/types/patterns change
- Update `archived-design/` — it's archived for a reason
