# Approve Proposal Command

Approve a draft proposal and integrate it into the roadmap.

## Usage

```
/approve-proposal <proposal-name>
```

Example: `/approve-proposal as-conversion` (approves `as-conversion-proposal.md`)

---

## Workflow

### Step 1: Locate and Validate the Draft

1. Find the proposal in `docs/ori_lang/proposals/drafts/`
2. Read the proposal to understand:
   - What it changes (syntax, types, patterns, stdlib, etc.)
   - Which compiler phases it affects
   - Any dependencies on other proposals or phases

### Step 2: Move to Approved

1. Move the file from `drafts/` to `approved/`:
   ```bash
   git mv docs/ori_lang/proposals/drafts/<name>-proposal.md docs/ori_lang/proposals/approved/
   ```

2. Update the proposal's **Status** field from `Draft` to `Approved`:
   ```markdown
   **Status:** Approved
   ```

3. Add an **Approved** date field:
   ```markdown
   **Approved:** YYYY-MM-DD
   ```

### Step 3: Determine Target Phase

Map the proposal to the appropriate roadmap phase based on what it affects:

| Proposal Type | Target Phase | Phase File |
|---------------|--------------|------------|
| Syntax changes | Phase 15 | `phase-15-syntax-proposals.md` |
| New traits (prelude) | Phase 3 | `phase-03-traits.md` |
| Stdlib additions | Phase 7 | `phase-07-stdlib.md` |
| Type system changes | Phase 1-2 | `phase-01-type-system.md` or `phase-02-type-inference.md` |
| Pattern additions | Phase 8 | `phase-08-patterns.md` |
| Capability changes | Phase 6 | `phase-06-capabilities.md` |
| Testing framework | Phase 14 | `phase-14-testing.md` |
| Tooling (formatter, LSP) | Phase 22 | `phase-22-tooling.md` |

Some proposals affect multiple phases. Add entries to each affected phase.

### Step 4: Add to Phase File

Add a new section to the appropriate `plans/roadmap/phase-XX-*.md` file:

```markdown
## X.Y Proposal Name

**Proposal**: `proposals/approved/<name>-proposal.md`

Brief description of what this implements.

### Implementation

- [ ] **Implement**: [First task] — [spec reference if applicable]
  - [ ] **Rust Tests**: `path/to/rust/tests`
  - [ ] **Ori Tests**: `tests/spec/category/file.ori`
  - [ ] **LLVM Support**: LLVM codegen for [feature]
  - [ ] **LLVM Rust Tests**: `ori_llvm/tests/feature_tests.rs`

- [ ] **Implement**: [Second task]
  - [ ] **Rust Tests**: ...
  - [ ] **Ori Tests**: ...
  - [ ] **LLVM Support**: ...
  - [ ] **LLVM Rust Tests**: ...

[Continue for all implementation tasks from the proposal]
```

Follow the existing format in the phase file. Break down the proposal's implementation section into discrete, checkable tasks.

### Step 5: Update plan.md

If the proposal is referenced in `plans/roadmap/plan.md` (under "Draft Proposals Pending Review" or similar sections):

1. Remove it from the drafts section
2. Add a note that it's been approved and which phase it's in

Example change:
```markdown
// Before (in drafts section)
- [ ] **`as` Conversion Syntax** — Replace `int()`, `float()`, `str()`, `byte()` with `as`/`as?`
  - Proposal: `proposals/drafts/as-conversion-proposal.md`
  - **Affects**: Phase 7 (Stdlib), Phase 15 (Syntax)

// After (remove from drafts, or mark as approved)
- [x] **`as` Conversion Syntax** — APPROVED → See Phase 15.7
```

### Step 6: Update priority-and-tracking.md

Add the approved proposal to the appropriate section in `plans/roadmap/priority-and-tracking.md`:

1. If it's immediately actionable, add to "What's Next (Priority Order)"
2. If it's blocked on other phases, note the dependency
3. Update the phase status if this adds new work

Example addition:
```markdown
### Recently Approved Proposals

**`as` Conversion Syntax** — Approved YYYY-MM-DD
- Proposal: `proposals/approved/as-conversion-proposal.md`
- Implementation: Phase 15.7
- Blocked on: Phase 3 (needs As<T> trait)
```

### Step 7: Update Spec (If Required)

If the proposal introduces new syntax, types, or semantics:

1. Update the relevant spec file in `docs/ori_lang/0.1-alpha/spec/`
2. Update `CLAUDE.md` if syntax/types/patterns are affected
3. Follow the rules in `.claude/rules/ori-lang.md`

### Step 8: Commit

Create a commit with:
```
docs(proposal): approve <proposal-name>

- Move from drafts/ to approved/
- Add implementation plan to Phase X
- Update roadmap tracking

Proposal: docs/ori_lang/proposals/approved/<name>-proposal.md
```

---

## Checklist

Before completing, verify:

- [ ] Proposal moved from `drafts/` to `approved/`
- [ ] Status field updated to `Approved`
- [ ] Approved date added
- [ ] Implementation tasks added to appropriate phase file(s)
- [ ] `plan.md` updated (if proposal was listed there)
- [ ] `priority-and-tracking.md` updated
- [ ] Spec updated (if proposal affects language semantics)
- [ ] `CLAUDE.md` updated (if proposal affects syntax/types/patterns)
- [ ] Changes committed

---

## Reference: Proposal Status Lifecycle

```
Draft → Approved → Implemented
  ↓
Rejected (moved to rejected/)
```

- **Draft**: Under consideration, may change
- **Approved**: Accepted for implementation, spec is final
- **Implemented**: Code complete, tests passing
- **Rejected**: Not accepted (with rationale documented)
