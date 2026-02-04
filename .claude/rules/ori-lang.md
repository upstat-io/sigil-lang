---
paths:
  - "**/docs/ori_lang/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Last expression IS the value. Exit via `?`/`break`/`panic`. Never document `return`.

# Ori Documentation

Design docs archived to `archived-design/`. Do not update.

## Sync Rules

**If `spec/` changed:**
- Sync to `.claude/rules/ori-syntax.md` if syntax/types/patterns affected
- Update `guide/` examples
- Ask: "Create draft proposal?"

**If `.claude/rules/ori-syntax.md` changed:**
- Verify consistent with `spec/`
- If new feature, update spec first

**If changing syntax:**
- Update `grammar.ebnf`
- Update ALL example code
- Update `.claude/rules/ori-syntax.md`

**If changing operator behavior:**
- Update `operator-rules.md`
- Verify: `ori_typeck/operators.rs`, `ori_eval/interpreter/`

## Never Do
- Examples that don't match spec
- Update docs without updating `.claude/rules/ori-syntax.md`
- Update `archived-design/`
