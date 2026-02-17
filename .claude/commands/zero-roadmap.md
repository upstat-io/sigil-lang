# Zero Roadmap Command

Reset the entire roadmap to pending status. This is a mechanical operation that modifies only status markers — no content changes.

## Usage

```
/zero-roadmap
```

No arguments. Operates on all section files in `plans/roadmap/`.

---

## Workflow

### Step 1: Confirm with User

Before making any changes, confirm:

```
WARNING: ROADMAP ZERO RESET

This will reset ALL roadmap items to pending status:
- All section `status:` → `not-started`
- All subsection `status:` → `not-started`
- All `[x]` checkboxes → `[ ]`

Content and descriptions will NOT be modified.

This is typically done after major refactoring to force re-verification of all features.

Proceed with zero reset?
```

Options:
1. **Yes, reset everything** — Proceed with full reset
2. **Show me what will change first** — List sections and checkbox counts
3. **Cancel** — Abort operation

### Step 2: Process Each Section File

For each `plans/roadmap/section-*.md` file:

#### 2a. Update YAML Frontmatter

1. Change top-level `status:` to `not-started`
2. Change every subsection `status:` to `not-started`

**Before:**
```yaml
status: in-progress
sections:
  - id: "1.1"
    title: Primitive Types
    status: complete
  - id: "1.2"
    title: Parameter Type Annotations
    status: in-progress
```

**After:**
```yaml
status: not-started
sections:
  - id: "1.1"
    title: Primitive Types
    status: not-started
  - id: "1.2"
    title: Parameter Type Annotations
    status: not-started
```

#### 2b. Update Body Checkboxes

Replace all `[x]` with `[ ]` in the body (after the YAML frontmatter).

**Preserve:**
- All text content
- Checkbox structure and nesting
- Notes, descriptions, and comments

**Only change:**
- `- [x]` → `- [ ]`

### Step 3: Record Zero Reset in Overview

Append an entry to the **Zero Reset Log** section in `plans/roadmap/00-overview.md`.

If the section doesn't exist yet, add it at the end of the file:

```markdown
---

## Zero Reset Log

| Date | Notes |
|------|-------|
| YYYY-MM-DD HH:MM UTC | (reason if given, otherwise blank) |
```

If it already exists, append a new row to the table with the current UTC timestamp.

Also update any completion statistics in the overview if present.

### Step 4: Report Summary

After processing all files, report:

```
Roadmap Reset Complete

Processed X section files:
- Section 1: Type System — 45 items reset
- Section 2: Type Inference — 23 items reset
- ...

Total: Y checkboxes reset to pending
All frontmatter statuses set to not-started

Next step: Run /verify-roadmap to systematically verify each item
```

---

## Important Notes

- This command does NOT verify whether features work
- This command does NOT modify any code or tests
- This command ONLY modifies `plans/roadmap/section-*.md` and `00-overview.md`
- Each zero reset is logged with a UTC timestamp in the overview's Zero Reset Log
- After running this, use `/verify-roadmap` to systematically verify and re-mark items

---

## Files Modified

- `plans/roadmap/section-*.md` — All section files
- `plans/roadmap/00-overview.md` — Overview (if it has stats)
