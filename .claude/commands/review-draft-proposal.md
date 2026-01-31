# Review Draft Proposal Command

Review a draft proposal, analyze implications, and (if approved) integrate into the roadmap.

**Usage:** `/review-draft-proposal [proposal-name]`
- With argument: `/review-draft-proposal as-conversion` reviews `as-conversion-proposal.md`
- Without argument: Auto-selects best draft to review

---

## Core Principle

> **Lean core, rich libraries** — Compiler implements only constructs requiring special syntax or static analysis. Everything else belongs in stdlib.

---

## Workflow Overview

1. Select proposal (if no argument)
2. Read and understand
3. Language purity analysis
4. Dependency analysis
5. Conflict check with approved proposals
6. Present analysis and ask questions
7. Walk through recommendations one-by-one
8. Confirm approval
9. Execute approval workflow
10. Verify documentation formatting (final step)

---

## Phase 1: Selection & Reading

### Step 1: Select Proposal (if no argument)

List drafts in `docs/ori_lang/proposals/drafts/` and evaluate:
- **Completeness**: Has Summary, Problem Statement, Design sections?
- **Dependencies**: Are blockers already approved?
- **Impact**: Does it unblock other work?
- **Simplicity**: Simpler = easier to review first

Present selection and confirm with `AskUserQuestion` before proceeding.

### Step 2: Read and Understand

Read the proposal and related spec files. Identify:
- What changes (syntax, types, patterns, stdlib)
- The problem being solved
- Which compiler phases affected
- Dependencies on other proposals

---

## Phase 2: Analysis

### Step 3: Language Purity Analysis

**Classification:**
| Category | Requires Compiler? |
|----------|-------------------|
| New syntax/keywords | YES |
| Static analysis | YES |
| Built-in type | MAYBE — could be library with operator traits? |
| Built-in method | MAYBE — could be extension/impl? |
| Stdlib addition | NO |

**Ask for each feature:** "Can this be implemented in pure Ori using existing or planned language features?"
- YES → Should be library, not compiler
- NO → Identify missing language feature that would enable it

**Present findings:**
```
## Purity Analysis
**Can be pure Ori?** [YES/NO/PARTIALLY]
**If not, why:** [reasons]
**Missing features that would enable purity:** [list with status: exists/draft/missing]
**Recommendation:** [Proceed/BLOCKED/Revise to library]
```

### Step 4: Dependency Analysis

**Check explicit dependencies** (from proposal's `Depends On:` field):
- ✅ Approved — in `proposals/approved/`
- 📝 Draft — in `proposals/drafts/` (review that first)
- ❌ Missing — BLOCKER

**Check implicit dependencies:**
- Uses syntax that doesn't exist?
- Assumes undefined traits?
- Requires unimplemented type features?

**If blockers exist:** Cannot approve. Offer options via `AskUserQuestion`:
1. "Draft blocking proposals" — create drafts, then return
2. "Defer this proposal" — stop, work on dependencies first
3. "Mark as blocked" — add BLOCKED status to proposal

### Step 5: Check Conflicts with Approved Proposals

Grep the draft for potential conflicts:
- Accessor patterns: `.0`, `.1`, `.value`, `.inner`
- Capability naming: `uses Async` (should be `uses Suspend`)
- Any syntax that might overlap with approved proposals

Search `docs/ori_lang/proposals/approved/` for related topics. If conflicts found, present each:
```
### Conflict: [Topic]
**Draft says:** [code]
**Approved `<name>` says:** [code]
```
Ask user to resolve via `AskUserQuestion` before proceeding.

---

## Phase 3: Recommendation

### Step 6: Present Analysis

Present structured analysis (NO recommendation yet):

**Summary:** 2-3 sentences on what proposal does

**Purity Assessment:** Appropriately in compiler vs library?

**Dependency Status:** All satisfied? Any blockers?

**Strengths:**
- Alignment with Ori design philosophy
- Benefits to users
- What it does well

**Concerns:** (any of these that apply)
- Consistency with existing patterns
- Unnecessary complexity
- Unhandled edge cases
- Ambiguous specification
- Implementation burden
- Overlooked alternatives
- Breaking changes
- Incomplete spec/grammar/examples

### Step 7: Ask Clarifying Questions

**Before any recommendation**, use `AskUserQuestion` to resolve:
- Unclear requirements or edge cases
- Design trade-offs with multiple valid approaches
- Scope clarifications
- Purity trade-offs (library vs compiler)

For each question: List recommended option first with "(Recommended)" suffix.

### Step 8: Present Recommendation

**STOP if unresolved blockers exist.** Blocked proposals cannot be approved.

Recommendations:
- **APPROVE** — Ready as-is
- **APPROVE WITH CHANGES** — Good but needs adjustments (list them)
- **BLOCKED** — Has unresolved dependencies
- **DEFER** — Needs more work
- **REJECT** — Fundamentally flawed

### Step 9: Interactive Change Review

For each recommended change, walk through one-by-one:

```
### Change N: [Topic]
**Current:** [code from proposal]
**Recommended:** [suggested change]
**Rationale:** [why better]
**Alternatives:** [if any]
```

Use `AskUserQuestion` for each. Continue until all addressed.

### Step 10: Summarize and Confirm

Present decision summary:
```
## Decisions
| Aspect | Decision |
|--------|----------|
| [Topic] | [Choice] |

## Final Status
**Dependencies:** [All satisfied / BLOCKED by X, Y]
**Purity:** [Pure library / Justified compiler / Needs revision]
**Recommendation:** [APPROVE / BLOCKED / DEFER / REJECT]
```

Ask user via `AskUserQuestion`:
- If blocked: Draft blockers / Defer / Mark as blocked
- If no blockers: Approve / Show updated proposal / Defer / Reject

Only proceed to approval workflow if user confirms approval.

---

## Phase 4: Approval Workflow

Execute only after user confirms approval AND no blockers exist.

### Step 11: Update and Move Proposal

- [ ] Apply all approved changes
- [ ] Update `Status:` from `Draft` to `Approved`
- [ ] Add `Approved: YYYY-MM-DD`
- [ ] Remove any `## Blockers` section
- [ ] `git mv docs/ori_lang/proposals/drafts/<name>-proposal.md docs/ori_lang/proposals/approved/`

### Step 12: Determine Target Phase

| Proposal Type | Phase File |
|---------------|------------|
| Syntax changes | `phase-15-syntax-proposals.md` |
| New traits (prelude) | `phase-03-traits.md` |
| Stdlib additions | `phase-07-stdlib.md` |
| Type system | `phase-01-type-system.md` or `phase-02-type-inference.md` |
| Patterns | `phase-08-patterns.md` |
| Capabilities | `phase-06-capabilities.md` |
| Testing framework | `phase-14-testing.md` |
| Tooling | `phase-22-tooling.md` |

Some proposals affect multiple phases — add entries to each.

### Step 13: Add to Phase File

Add section to `plans/roadmap/phase-XX-*.md`:
```markdown
## X.Y Proposal Name
**Proposal**: `proposals/approved/<name>-proposal.md`

Brief description.

### Implementation
- [ ] **Implement**: [task] — [spec ref]
  - [ ] **Rust Tests**: `path/to/tests`
  - [ ] **Ori Tests**: `tests/spec/category/file.ori`
  - [ ] **LLVM Support**: [feature]
  - [ ] **LLVM Rust Tests**: `ori_llvm/tests/feature_tests.rs`
```

### Step 14: Update Tracking Files

- [ ] Remove from drafts section in `plans/roadmap/plan.md` (if listed)
- [ ] Add to `plans/roadmap/priority-and-tracking.md`:
```markdown
**Proposal Name** — ✅ APPROVED YYYY-MM-DD
- Proposal: `proposals/approved/<name>-proposal.md`
- Implementation: Phase X.Y
- [Key features]
- Blocked on: [deps or "None"]
```

### Step 15: Update Spec and CLAUDE.md

If proposal introduces new syntax/types/semantics:
- [ ] Update relevant spec file in `docs/ori_lang/0.1-alpha/spec/`
- [ ] Update `grammar.ebnf` if syntax changes
- [ ] Update `CLAUDE.md` if syntax/types/patterns affected
- [ ] Follow rules in `.claude/rules/ori-lang.md`

### Step 16: Verify Documentation Formatting

**Before committing**, verify all modified documentation follows formatting rules.

**Check spec files against `.claude/rules/spec.md`:**
- [ ] Uses formal, declarative language (not "you can..." or tutorial tone)
- [ ] Technical terms in _italics_ on first use
- [ ] Syntax in `backticks`
- [ ] Normative keywords used correctly (must, shall, may, error)
- [ ] Informative sections marked with `> **Note:**`
- [ ] No inline EBNF (references grammar.ebnf instead)
- [ ] Examples follow `// Valid` / `// Invalid - reason` format

**Check CLAUDE.md and proposal files against `.claude/rules/ori-lang.md`:**
- [ ] Consistent with spec (no contradictions)
- [ ] Syntax/types/patterns synchronized across all docs

**If formatting issues are found**, present the problem and ask for resolution:

```
### Formatting Issue: [Location]
**Current text:**
> [problematic text]

**Issue:** [what rule is violated]

**Option A (Recommended):** [formal/correct version]
**Option B:** [alternative if applicable]

Examples of correct format:
- Spec style: "An associated type default applies when the impl omits the type."
- Tutorial style (AVOID): "You can omit the associated type if you want to use the default."
```

Use `AskUserQuestion` to resolve each formatting issue before proceeding.

**Common formatting scenarios:**

| Wrong | Right |
|-------|-------|
| "You can use `Self` to..." | "`Self` refers to..." |
| "This is useful for..." | "This enables..." |
| "When you write `type T = Self`..." | "The syntax `type T = Self`..." |
| "Don't forget to..." | "It is an error if..." |

### Step 17: Commit and Push

Invoke: `Skill(skill: "commit-push")`

Commit message format:
```
docs(proposal): approve <proposal-name>

- Move from drafts/ to approved/
- Add implementation plan to Phase X
- Update roadmap tracking
- Update spec ([affected files])
- Update CLAUDE.md with [feature]

Key decisions:
- [Decision 1]
- [Decision 2]

Proposal: docs/ori_lang/proposals/approved/<name>-proposal.md
```

---

## Final Checklist

**Analysis Phase:**
- [ ] Purity analysis completed — features pushed to library when possible
- [ ] Dependency analysis completed — no unresolved blockers
- [ ] Conflicts with approved proposals checked and resolved
- [ ] Strengths and concerns documented
- [ ] Clarifying questions asked BEFORE recommendation
- [ ] Each change reviewed one-by-one with user
- [ ] Decisions summarized
- [ ] User confirmed approval

**Approval Phase:**
- [ ] Proposal updated with approved changes
- [ ] Moved from `drafts/` to `approved/`
- [ ] Status updated to `Approved`, date added
- [ ] Implementation tasks added to phase file(s)
- [ ] `plan.md` updated (if applicable)
- [ ] `priority-and-tracking.md` updated
- [ ] Spec updated (if affects semantics)
- [ ] `grammar.ebnf` updated (if affects syntax)
- [ ] `CLAUDE.md` updated (if affects syntax/types/patterns)

**Formatting Verification (final step):**
- [ ] Spec files use formal/declarative language (no tutorial tone)
- [ ] Technical terms in italics, syntax in backticks
- [ ] Informative sections marked with `> **Note:**`
- [ ] All docs synchronized (no contradictions between spec/CLAUDE.md/proposal)
- [ ] Formatting issues resolved with user via `AskUserQuestion`
- [ ] Committed and pushed via `/commit-push`

---

## Quick Reference

### Blocker Resolution

If blockers exist, offer three options:
1. **Draft blockers** — Create missing proposals, then return to this review
2. **Defer** — Leave in drafts, work on dependencies separately
3. **Mark blocked** — Add BLOCKED status with dependency list

### Proposal Status Lifecycle

`Draft` → `Blocked` (if deps missing) → `Approved` (after deps resolved) → `Implemented`
`Draft` → `Rejected` (if fundamentally flawed)

### Purity Example

```
Proposal: Duration factory methods as built-ins

Q: Can Duration.from_seconds(s:) be pure Ori?
- Requires Type.method() → Associated functions ✅ (approved)
- Requires Duration + Duration → Operator traits ❌ (missing)

Conclusion: BLOCKED by operator-traits-proposal
Duration should move to library once operator traits exist.
```
