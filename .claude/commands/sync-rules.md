---
name: sync-rules
description: Sync all .claude/rules/*.md files - fix info, add missing info, condense if too big
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Sync Rules Files

Update all rules files in `.claude/rules/` to accurately reflect the current codebase. Fix outdated info, add missing info, and condense files that have grown too large.

## Target Directory

```
.claude/rules/
```

## Rules File Format

Every rules file MUST follow this structure:

```markdown
---
paths: **/<pattern>/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Title

## Section
- Bullet point (concise)
- Another point

## Key Files

| File | Purpose |
|------|---------|
| `file.rs` | Brief description |
```

## Style Requirements

### Concise Bullet Format

Rules files are **quick references**, not documentation. Keep entries terse:

**Good:**
```markdown
- **Arena**: `ExprArena` + `ExprId`, not `Box<Expr>`
- **Interning**: `Name` for identifiers, not `String`
```

**Bad:**
```markdown
- The arena pattern uses ExprArena to store expressions and ExprId to reference them, which is more memory efficient than using Box<Expr> for recursive structures.
```

### Size Limits

- **Target**: 50-80 lines per file
- **Maximum**: 120 lines
- If over limit: condense, remove redundancy, use tables

### Tables for Structured Info

Use tables for:
- Key files and their purposes
- Error codes and descriptions
- Commands and aliases
- Mappings (Ori type → Rust type, etc.)

### What to Include

- Architecture overview (brief)
- Key patterns and conventions
- Common operations / commands
- Error code ranges
- Key files table

### What NOT to Include

- Tutorial explanations
- Full API documentation
- Historical notes or changes
- Redundant info covered in other rules files

## Sync Process

1. **List all rules files**
   ```bash
   ls -la .claude/rules/*.md
   ```

2. **For each rules file:**

   a. **Read the rules file** and note its `paths:` pattern

   b. **Check corresponding codebase** (e.g., `compiler/ori_llvm/` for `llvm.md`)

   c. **Identify gaps:**
      - Missing crates or modules
      - Outdated commands or aliases
      - Missing error codes
      - Stale file references

   d. **Identify redundancy:**
      - Verbose explanations → condense to bullets
      - Duplicate info across files → keep in one place
      - Overly detailed sections → summarize

   e. **Update the file:**
      - Fix outdated info
      - Add missing info (concisely)
      - Condense if over ~80 lines

3. **Check for missing rules files:**
   - New crates without rules?
   - New major modules without coverage?

4. **Verify consistency:**
   - Cross-references accurate?
   - No conflicting info between files?

## Current Rules Files

| File | Pattern | Covers |
|------|---------|--------|
| `aot.md` | `**/aot/**` | AOT compilation, linking, mangling |
| `cargo.md` | `**Cargo.toml` | Cargo config, aliases |
| `compiler.md` | `**/compiler/**` | General compiler development |
| `diagnostic.md` | `**/diagnostic/**` | Error codes, diagnostics |
| `eval.md` | `**/eval/**` | Interpreter |
| `ir.md` | `**/ori_ir/**` | AST, spans, arenas |
| `llvm.md` | `**/llvm/**` | LLVM backend |
| `ori-lang.md` | — | Language documentation rules |
| `parse.md` | `**/parse/**` | Parser |
| `patterns.md` | `**/patterns/**` | Pattern system |
| `runtime.md` | `**/ori_rt/**` | Runtime library FFI |
| `spec.md` | `**/spec/**` | Language spec rules |
| `tests.md` | `**/tests/**` | Testing |
| `typeck.md` | `**/typeck/**` | Type checker |
| `types.md` | `**/ori_types/**` | Type system |

## Condensing Guidelines

### Before (verbose):
```markdown
## Memory Management

The compiler uses arena allocation for expressions. This means that instead of
using `Box<Expr>` which would require individual heap allocations for each
expression node, we use an `ExprArena` that stores all expressions in a
contiguous vector and uses `ExprId` indices to reference them.
```

### After (condensed):
```markdown
## Memory

- **Arena**: `ExprArena` + `ExprId`, not `Box<Expr>`
```

### Condensing Checklist

- [ ] Remove "This means that...", "In other words..."
- [ ] Remove motivation/rationale (that's for design docs)
- [ ] Convert paragraphs to bullet points
- [ ] Use tables for lists of 3+ related items
- [ ] Remove examples (link to tests/docs instead)

## Output

Report:
- Files updated and changes made
- Files condensed and by how much
- New files created (if any)
- Any issues found (stale refs, conflicts)
