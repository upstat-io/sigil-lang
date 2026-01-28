---
name: sync-all
description: Run all documentation sync commands in proper dependency order
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, Skill
---

# Sync All Documentation

Run all documentation sync commands in the correct dependency order to ensure consistency across the Ori project.

## Sync Order

The commands must run in this order due to dependencies:

```
1. /sync-spec          Spec is authoritative → update it first
        ↓
2. /sync-grammar       Grammar must match spec → update after spec
        ↓
3. /sync-compiler-docs Design docs describe implementation
        ↓
4. /sync-roadmap-webpage Website reflects current status
```

## Dependency Rationale

| Order | Command | Depends On | Updates |
|-------|---------|------------|---------|
| 1 | `/sync-spec` | User changes, code changes | `docs/ori_lang/0.1-alpha/spec/*.md` |
| 2 | `/sync-grammar` | Spec files | `docs/ori_lang/0.1-alpha/spec/grammar.ebnf` |
| 3 | `/sync-compiler-docs` | Implementation, spec | `docs/compiler/design/` |
| 4 | `/sync-roadmap-webpage` | Roadmap plans | `website/src/pages/roadmap.astro` |

## Execution Process

### Step 1: Sync Spec (`/sync-spec`)

Update the language specification to reflect recent changes:
- Apply formal, declarative writing style
- Add new language features to appropriate spec files
- Update constraints and semantics
- Mark informative content appropriately

**Skip if:** No language changes were made (only implementation/docs changes)

### Step 2: Sync Grammar (`/sync-grammar`)

Update `grammar.ebnf` to match the spec:
- Add new productions for new syntax
- Update existing productions for changed syntax
- Ensure all spec syntax is represented

**Skip if:** No syntax changes were made

### Step 3: Sync Compiler Docs (`/sync-compiler-docs`)

Update compiler design documentation:
- Document new AST nodes, patterns, types
- Update architecture docs if structure changed
- Document new algorithms or approaches

**Skip if:** No implementation changes were made

### Step 4: Sync Roadmap Webpage (`/sync-roadmap-webpage`)

Update the website roadmap page:
- Update phase statuses from `plans/roadmap/priority-and-tracking.md`
- Update task completion from phase files
- Update test counts

**Skip if:** No roadmap progress was made

## Selective Sync

Not all syncs are always needed. Determine which to run:

| What Changed | Required Syncs |
|--------------|----------------|
| Language syntax | spec → grammar → compiler-docs |
| Language semantics (no syntax) | spec → compiler-docs |
| Implementation only | compiler-docs |
| Roadmap progress | roadmap-webpage |
| Everything | All four in order |

## Running the Sync

For each applicable sync command:

1. **Announce** which sync is starting
2. **Execute** the sync using the Skill tool
3. **Report** what was updated
4. **Continue** to next sync

## Example Output

```
## Sync All Documentation

### 1/4: Syncing Spec
Running /sync-spec...
- Updated 09-expressions.md: added timeout pattern semantics
- Updated 10-patterns.md: added timeout to compiler patterns list

### 2/4: Syncing Grammar
Running /sync-grammar...
- Updated grammar.ebnf: added timeout_expr production

### 3/4: Syncing Compiler Docs
Running /sync-compiler-docs...
- Updated docs/compiler/design/06-pattern-system/index.md: documented TimeoutPattern

### 4/4: Syncing Roadmap Webpage
Running /sync-roadmap-webpage...
- Phase 10 status: partial → complete
- Updated test counts: 847 Rust, 312 Ori spec

## Summary
- 4 syncs completed
- 5 files modified
```

## Verification

After all syncs complete, optionally verify:

```bash
# Check website builds
cd website && bun run build

# Check for broken cross-references (manual review)
```

## Notes

- Each sync command has its own detailed instructions
- If a sync fails or has issues, fix before continuing
- Report any inconsistencies found during sync
- This command coordinates; individual syncs do the actual work
