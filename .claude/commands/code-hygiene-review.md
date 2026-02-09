---
name: code-hygiene-review
description: Review code for hygiene violations and generate a fix plan. NOT refactoring — purely surface cleanliness.
allowed-tools: Read, Grep, Glob, Task, Bash, EnterPlanMode
---

# Code Hygiene Review

Review code for hygiene violations against `.claude/rules/code-hygiene.md` and generate a plan to fix them.

**Hygiene is NOT refactoring.** No behavior changes, no API changes, no moving things between modules. Just making existing code clean:
- Dead code, unused imports, stale comments
- Naming inconsistencies
- File/method ordering violations
- Comment style violations (banners, restating code)
- Derive vs manual impl misuse
- Dead public surface
- Import organization

## Target

`$ARGUMENTS` specifies the target (crate, directory, or file):
- `/code-hygiene-review compiler/ori_lexer` — review a crate
- `/code-hygiene-review compiler/ori_types/src/infer/` — review a directory
- `/code-hygiene-review compiler/ori_parse/src/lib.rs` — review a single file

If no argument: ask the user what to review.

## Execution

### Step 1: Load Rules

Read `.claude/rules/code-hygiene.md` to have the full rule set in context.

### Step 2: Inventory Target

For the target path, get a complete file list with line counts:
```bash
find {target} -name "*.rs" -exec wc -l {} \; | sort -rn
```

### Step 3: Read All Files

Read EVERY `.rs` file in the target. For files > 500 lines, read in segments. Do NOT skip test modules — they have hygiene rules too (but relaxed: section banners OK in tests).

### Step 4: Audit Each File

For each file, check every rule category from `code-hygiene.md`:

**File Organization:**
- [ ] `//!` module doc present?
- [ ] Sections in correct order? (mods → imports → types → impls → fns → tests)
- [ ] Imports in 3 groups with blank-line separators?

**Impl Block Ordering:**
- [ ] Constructors first?
- [ ] Accessors before predicates before operations before helpers?
- [ ] pub before private within groups?

**Naming:**
- [ ] Function names follow verb-prefix conventions?
- [ ] Variable names scope-scaled? (no `token_kind_result` in a 3-line scope, no `t` in a 50-line function)
- [ ] Standard abbreviations used consistently?

**Struct/Enum Fields:**
- [ ] Primary data first, flags last?
- [ ] Inline comments where purpose isn't obvious?

**Comments:**
- [ ] No decorative banners? (`───`, `===`, `***`, `---`)
- [ ] No comments restating code?
- [ ] No commented-out code?
- [ ] `///` on all pub items?
- [ ] WHY comments, not WHAT?

**Derive vs Manual:**
- [ ] Any manual trait impls that duplicate derive behavior?

**Visibility:**
- [ ] Any dead pub items? (pub but unused outside crate)
- [ ] Any dead code? (unused functions, imports, variants)

**Style:**
- [ ] All `#[allow(clippy)]` have `reason`?
- [ ] Functions under 50 lines? (note: dispatch tables exempt)
- [ ] No dead/commented-out code?

### Step 5: Compile Findings

Organize findings by file, categorized as:

- **FIX** — Clear violation, mechanical fix (dead code, banner comment, missing doc)
- **IMPROVE** — Suboptimal but not wrong (ordering, naming, derive-vs-manual)
- **NOTE** — Observation, not actionable (acceptable exceptions, context for reviewer)

### Step 6: Generate Plan

Use **EnterPlanMode** to create a fix plan. The plan should:

1. List every FIX and IMPROVE finding with `file:line` references
2. Group by file (not by rule category — easier to fix file-by-file)
3. Estimate the scope: "N files, ~M changes"
4. Order: fixes that might affect other files first (dead pub removal), then file-local fixes

### Plan Format

The plan should be structured as:

```
## Hygiene Review: {target}

**Scope:** N files, ~M findings (X fix, Y improve)

### {filename}

1. **[FIX]** `line:NN` — {description}
2. **[IMPROVE]** `line:NN` — {description}
...

### {next filename}
...

### Execution Order

1. Dead pub removal (may affect other crates)
2. File-by-file hygiene (independent, can parallelize)
3. Run `./clippy-all.sh` to verify no regressions
4. Run `./test-all.sh` to verify no behavior changes
```

## Important Rules

1. **No behavior changes** — Hygiene fixes must be purely cosmetic/organizational
2. **No refactoring** — Don't extract functions, move modules, or change APIs
3. **Test code is relaxed** — Section banners (`// === Section ===`) are OK in `#[cfg(test)]` modules
4. **Dispatch tables exempt** — Large match statements mapping tokens/tags are not "long functions"
5. **Read the code** — Don't grep-audit. Read every file to understand context before flagging
6. **Be specific** — Every finding must have `file:line` and a concrete fix description
7. **Don't over-flag** — If something is a judgment call and the current code is reasonable, it's a NOTE not a FIX
