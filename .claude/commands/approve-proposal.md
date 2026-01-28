# Approve Proposal Command

Review a draft proposal, analyze its implications, and (if approved) integrate it into the roadmap.

## Usage

```
/approve-proposal <proposal-name>
```

Example: `/approve-proposal as-conversion` (reviews and potentially approves `as-conversion-proposal.md`)

---

## Workflow

### Step 1: Locate and Read the Draft

1. Find the proposal in `docs/ori_lang/proposals/drafts/`
2. Read the entire proposal carefully to understand:
   - What it changes (syntax, types, patterns, stdlib, etc.)
   - The motivation and problem being solved
   - The proposed solution and alternatives considered
   - Which compiler phases it affects
   - Any dependencies on other proposals or phases
3. Read related spec files to understand how the proposal fits with existing language features

### Step 2: Present Initial Review

Present a structured review to the user covering:

#### Summary
- Brief (2-3 sentence) summary of what the proposal does

#### Strengths
- What the proposal does well
- How it aligns with Ori's design philosophy
- Benefits to language users

#### Concerns
Raise any issues found, including but not limited to:
- **Consistency**: Does it fit with existing language patterns?
- **Complexity**: Does it add unnecessary complexity?
- **Edge cases**: Are there unhandled edge cases?
- **Ambiguity**: Is the specification clear and complete?
- **Implementation burden**: Is the implementation realistic?
- **Alternatives**: Were better alternatives overlooked?
- **Breaking changes**: Does it break existing code?
- **Spec completeness**: Are grammar, semantics, and examples complete?

#### Questions
- List any clarifying questions that need answers before approval

#### Recommendation
Provide a clear initial recommendation:
- **APPROVE**: Ready for implementation as-is
- **APPROVE WITH CHANGES**: Good proposal but needs adjustments (list them)
- **DEFER**: Needs more work before approval (explain what)
- **REJECT**: Fundamentally flawed or conflicts with language goals (explain why)

### Step 3: Interactive Recommendation Review

**If recommending changes**, walk through each recommendation one by one:

For each recommendation:

1. **Show the current syntax** from the proposal
2. **Show the recommended change** with concrete examples
3. **Explain the rationale** — why this change improves the proposal
4. **Present alternatives** if applicable
5. **Ask for user decision** using AskUserQuestion with clear options

Example format for each recommendation:

```
### Recommendation N: [Topic]

**Current proposal:**
```ori
[code from proposal]
```

**Recommended:**
```ori
[suggested change]
```

**Rationale:** [Why this is better — consistency with existing features, readability, etc.]

**Alternatives considered:**
- Option A: [description]
- Option B: [description]

[Use AskUserQuestion to get user's choice]
```

Continue until all recommendations have been addressed.

### Step 4: Summarize Decisions

After all recommendations are reviewed, present a summary table:

```markdown
## Summary of Decisions

| Aspect | Decision |
|--------|----------|
| [Topic 1] | [User's choice] |
| [Topic 2] | [User's choice] |
| ... | ... |
```

### Step 5: Confirm Approval

Ask the user if they want to:
1. **Approve** — Proceed with approval workflow using the decided changes
2. **Show updated proposal** — Display the full proposal with changes before approving
3. **Defer** — Leave in drafts for further consideration
4. **Reject** — Move to rejected with rationale

If the user chooses to defer or reject, stop here. Only proceed to Step 6+ if approving.

---

## Approval Workflow (Steps 6-12)

Only proceed with these steps after user confirms approval.

### Step 6: Update and Move Proposal

1. Update the proposal file with all approved changes
2. Update the **Status** field from `Draft` to `Approved`
3. Add an **Approved** date field: `**Approved:** YYYY-MM-DD`
4. Move the file from `drafts/` to `approved/`:
   ```bash
   git mv docs/ori_lang/proposals/drafts/<name>-proposal.md docs/ori_lang/proposals/approved/
   ```

### Step 7: Determine Target Phase

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

### Step 8: Add to Phase File

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

### Step 9: Update plan.md

If the proposal is referenced in `plans/roadmap/plan.md` (under "Draft Proposals Pending Review" or similar sections):

1. Remove it from the drafts section
2. Add a note that it's been approved and which phase it's in

### Step 10: Update priority-and-tracking.md

Add the approved proposal to the "Approved Proposals" section in `plans/roadmap/priority-and-tracking.md`:

```markdown
**Proposal Name** — ✅ APPROVED YYYY-MM-DD
- Proposal: `proposals/approved/<name>-proposal.md`
- Implementation: Phase X.Y
- [Brief description of key features]
- Blocked on: [dependencies, or "None"]
```

### Step 11: Update Spec and CLAUDE.md

If the proposal introduces new syntax, types, or semantics:

1. Update the relevant spec file in `docs/ori_lang/0.1-alpha/spec/`
2. Update `grammar.ebnf` if syntax changes
3. Update `CLAUDE.md` if syntax/types/patterns are affected
4. Follow the rules in `.claude/rules/ori-lang.md`

### Step 12: Commit

Create a commit with:
```
docs(proposal): approve <proposal-name>

- Move from drafts/ to approved/
- Add implementation plan to Phase X
- Update roadmap tracking
- Update spec ([list affected spec files])
- Update CLAUDE.md with [feature] syntax

Key design decisions:
- [Decision 1]
- [Decision 2]
- [etc.]

Proposal: docs/ori_lang/proposals/approved/<name>-proposal.md

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Checklist

Before completing, verify:

- [ ] Proposal reviewed with user (strengths, concerns, questions)
- [ ] Each recommendation reviewed one-by-one with user
- [ ] User decisions summarized
- [ ] User confirmed approval
- [ ] Proposal updated with approved changes
- [ ] Proposal moved from `drafts/` to `approved/`
- [ ] Status field updated to `Approved`
- [ ] Approved date added
- [ ] Implementation tasks added to appropriate phase file(s)
- [ ] `plan.md` updated (if proposal was listed there)
- [ ] `priority-and-tracking.md` updated
- [ ] Spec updated (if proposal affects language semantics)
- [ ] `grammar.ebnf` updated (if proposal affects syntax)
- [ ] `CLAUDE.md` updated (if proposal affects syntax/types/patterns)
- [ ] Changes committed with design decisions in commit message

---

## Example: Recommendation Walkthrough

Here's how a typical recommendation review might look:

---

### Recommendation 1: Guard Syntax

**Current proposal:**
```ori
@classify (n: int).match(n < 0) -> str = "negative"
```

**Recommended:**
```ori
@classify (n: int) -> str if n < 0 = "negative"
```

**Rationale:** The `if` syntax mirrors existing `for x in items if cond` syntax in Ori. It reads more naturally: "classify n returning str if n < 0". The `.match()` on the parameter list is unusual and inconsistent with how guards work in match arms.

[AskUserQuestion: "Use `if` guard syntax instead of `.match()` on params?"]

---

### Recommendation 2: Type Annotation Rules

**Question:** When can type annotations be omitted from clause parameters?

**Option A — Required on first clause only:**
```ori
@factorial (0: int) -> int = 1      // type required
@factorial (n) -> int = ...         // type optional
```

**Option B — Always required:**
```ori
@factorial (0: int) -> int = 1
@factorial (n: int) -> int = ...
```

**Rationale for Option A:** Reduces repetition while maintaining clarity. The first clause establishes the contract; subsequent clauses focus on patterns.

[AskUserQuestion: "When are type annotations required?"]

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
