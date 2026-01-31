---
paths: **/docs/ori_lang/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

# Ori Documentation Rules

**Note:** Design docs archived to `archived-design/`. Do not update them.

## Sync Requirements

**If `spec/` changed:**
- Sync to `/CLAUDE.md` if syntax, types, or patterns affected
- Update `guide/` examples to match
- Update `modules/` if stdlib affected
- Ask: "Create draft proposal in `proposals/drafts/`?"

**If `/CLAUDE.md` changed:**
- Verify consistent with `spec/`
- If CLAUDE.md introduces new feature, update spec first

**If adding new type:**
- Add to `spec/06-types.md`
- Update `/CLAUDE.md` Types section
- Ask: "Create draft proposal?"

**If adding new pattern:**
- Add to `spec/10-patterns.md`
- Update `/CLAUDE.md` Patterns section
- Ask: "Create draft proposal?"

**If changing syntax:**
- Update grammar in `spec/`
- Update `spec/03-lexical-elements.md` if tokens changed
- Update ALL example code in spec
- Update `/CLAUDE.md`
- Ask: "Create draft proposal?"

## Document Types

| Type | Location | Purpose | Tone |
|------|----------|---------|------|
| Spec | `spec/` | Define what IS valid Ori | Formal, normative |
| Proposals | `proposals/` | Capture decisions and rationale | Explanatory |

## Never Do

- Add examples that don't match spec
- Update docs without updating `/CLAUDE.md` for syntax/types/patterns
- Update `archived-design/`
