# Full Design Documentation Audit

Systematically audit **every** design doc for accuracy and completeness. This command goes through each document one by one, using separate agents to gather implementation details before making any edits.

## Scope

All design documentation across three areas:

| Area | Path |
|------|------|
| Compiler | `docs/compiler/design/**/*.md` |
| Formatter | `docs/tooling/formatter/design/**/*.md` |
| LSP | `docs/tooling/lsp/design/**/*.md` |

## Process

### Phase 0: Document Discovery

First, scan for all design docs using Glob:

```
docs/compiler/design/**/*.md
docs/tooling/formatter/design/**/*.md
docs/tooling/lsp/design/**/*.md
```

This ensures newly added docs are included and removed docs are skipped.

### Phase 1: Information Gathering (Parallel Agents)

For **each** design doc discovered, spawn a dedicated **Explore agent** to:

1. **Read the design doc** completely
2. **Find corresponding source files** in `compiler/` using:
   - Grep for types/functions mentioned in the doc
   - Glob for relevant module files
3. **Identify discrepancies**:
   - Outdated information (implementation changed)
   - Missing information (features not documented)
   - Incorrect information (doc contradicts code)
   - Incomplete sections (TODO, placeholders, stubs)
4. **Return a structured report** with:
   - Doc path
   - Source files examined
   - List of issues found (with specific line references)
   - Suggested corrections

**Parallelization Strategy:**
- Launch agents in batches of 3-5 (to avoid overwhelming the system)
- Group by area (all compiler docs, then formatter, then LSP)
- Wait for batch completion before starting next batch

### Phase 2: Edit Planning

After all agents report back:

1. **Aggregate findings** into a prioritized list
2. **Group by severity**:
   - Critical: Factually incorrect information
   - High: Missing important features/APIs
   - Medium: Outdated examples or minor inaccuracies
   - Low: Style/formatting issues, minor omissions
3. **Create an edit plan** for each doc that needs changes

### Phase 3: Systematic Edits

For each doc requiring changes:

1. **Read the current doc content**
2. **Apply corrections** based on agent findings
3. **Verify accuracy** against source code
4. **Maintain writing style** (see guidelines below)

## Agent Prompt Template

Use this template when spawning Explore agents:

```
Audit design doc: {DOC_PATH}

1. Read the entire design doc
2. Find source files in compiler/ that implement what the doc describes
3. Compare doc claims against actual implementation
4. Report:
   - Source files examined (with paths)
   - ACCURATE: Sections that correctly describe the implementation
   - OUTDATED: Information that no longer matches (with specifics)
   - MISSING: Features/APIs in code but not documented
   - INCORRECT: Factual errors (doc says X, code does Y)
   - INCOMPLETE: Stubs, TODOs, placeholder sections

Focus on substantive issues, not minor wording preferences.
Return findings in a structured format.
```

## Writing Style Guidelines

When making edits, follow these rules from `/sync-docs`:

### Document the Current State

- Write in present tense
- Describe what IS, not what changed
- No "was changed to", "previously", "now"
- Write as if for someone who never saw previous versions

### Content Focus

- Explain WHY and HOW, not just what
- Document design decisions and trade-offs
- Include diagrams where helpful
- Reference the spec for normative definitions

### Exclusions

- No test counts or coverage percentages
- No volatile metrics
- No progress updates or completion notes

## Output

After completion, report:

1. **Summary Statistics**:
   - Total docs audited
   - Docs with no issues
   - Docs updated
   - Issues found by severity

2. **Changes Made**:
   - List each modified file
   - Summary of changes per file

3. **Remaining Issues**:
   - Any issues that couldn't be resolved
   - Docs that need further investigation

## User Input

$ARGUMENTS
