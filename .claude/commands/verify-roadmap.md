# Verify Roadmap Command

Systematically verify roadmap items one by one. This command does NOT implement features — it only verifies status and annotates items that need better test coverage.

## Usage

```
/verify-roadmap [section]
```

- No args: Start from Section 1, Item 1
- `section-4`, `4`: Start from Section 4
- `continue`: Resume from last verified item (if tracking exists)

---

## Core Principle

**Verification only, no implementation.** For each item:

1. **Can verify → verified** — Tests pass, feature works → mark `[x]`
2. **Cannot verify → annotate + pending** — Insufficient tests → add test tasks, leave `[ ]`
3. **Move on** — Never fix code, never write features, just verify and annotate

---

## Workflow

### Step 1: Load Section

Read the section file. Extract all checkable items with their context.

### Step 2: For Each Item (Sequential)

Process items **one at a time**, in document order:

#### 2a. Identify Verification Method

For each item, determine how to verify it:

| Item Type | Verification Method |
|-----------|---------------------|
| `**Implement**: X` | Find and run related Ori tests |
| `**Rust Tests**: path` | Check if Rust tests exist at path, run them |
| `**Ori Tests**: path` | Run specific Ori test file |
| `**LLVM Support**: X` | Run LLVM-specific tests |
| Generic checkbox | Context-dependent verification |

#### 2b. Attempt Verification

1. **Find related tests**:
   - Search `tests/spec/` for Ori tests
   - Search Rust test modules for `#[test]`
   - Check `tests/compile-fail/` for error tests

2. **Run tests**:
   ```bash
   # For specific Ori test file
   cargo st tests/spec/path/to/test.ori

   # For Rust tests in a module
   cargo test -p ori_types -- module_name

   # For LLVM tests
   ./llvm-test.sh
   ```

3. **Evaluate result**:
   - Tests exist AND pass → **Verified**
   - Tests exist but fail → **Not verified** (regression)
   - No tests exist → **Cannot verify**

#### 2c. Update Item Status

**If Verified:**
```markdown
- [x] **Implement**: Feature X ✅ (verified 2026-02-05)
```

**If Not Verified (regression):**
```markdown
- [ ] **Implement**: Feature X
  - ⚠️ REGRESSION: Tests exist but fail. Needs investigation.
```

**If Cannot Verify (no tests):**
```markdown
- [ ] **Implement**: Feature X
  - 🔍 NEEDS TESTS: Add verification tests before marking complete
    - [ ] Add test: [specific test description]
    - [ ] Add test: [edge case description]
```

#### 2d. Report Progress

After each item, briefly report:
```
✓ 1.1.1 Primitive int type — VERIFIED (tests/spec/types/primitives.ori passes)
✗ 1.1.2 Duration arithmetic — NEEDS TESTS (no LLVM arithmetic tests found)
✓ 1.1.3 Size literals — VERIFIED
```

### Step 3: Update Frontmatter

After completing a subsection, update its status in frontmatter:
- All items `[x]` → `status: complete`
- Mixed → `status: in-progress`
- All items `[ ]` → `status: not-started`

After completing a section, update section status based on subsection statuses.

### Step 4: Commit Checkpoint

After each section (not each item), offer to commit:
```
Section 1 verification complete.
- 42/50 items verified
- 8 items need additional tests

Commit checkpoint? (Allows resuming later)
```

---

## Verification Criteria

### What Counts as "Verified"

1. **Feature tests pass** — Ori spec tests exercise the feature and pass
2. **Error tests pass** — Compile-fail tests produce expected errors
3. **Rust tests pass** — Unit tests for the implementation pass
4. **Behavior matches spec** — Quick manual check against spec if unclear

### What Counts as "Cannot Verify"

1. **No tests exist** — Feature claimed complete but no test coverage
2. **Tests don't cover claim** — Tests exist but don't test the specific feature
3. **Tests are trivial** — Tests pass but don't meaningfully verify behavior

### What to Annotate

When adding "NEEDS TESTS" annotations, be specific:
```markdown
- 🔍 NEEDS TESTS:
  - [ ] Add test: Duration + Duration returns Duration
  - [ ] Add test: Duration overflow panics
  - [ ] Add test: Duration with negative value
```

NOT:
```markdown
- 🔍 NEEDS TESTS: Add more tests
```

---

## Important Constraints

### DO NOT:
- Fix bugs encountered during verification
- Implement missing features
- Modify test files
- Change any code outside `plans/roadmap/`

### DO:
- Run existing tests
- Read spec for expected behavior
- Annotate items with specific test requirements
- Update checkbox status based on verification
- Track what needs attention

### If You Find a Bug:
```markdown
- [ ] **Implement**: Feature X
  - ⚠️ BUG FOUND: [brief description]
  - Should be fixed before marking complete
```

Do NOT fix it. Just document and move on.

---

## Progress Tracking

### During Session

Maintain internal tracking:
```
Current: Section 1, Item 1.1.3
Verified: 12
Needs tests: 4
Regressions: 1
```

### Between Sessions

If verification is interrupted, the last commit checkpoint shows progress. Resume using:
```
/verify-roadmap continue
```

Or specify where to start:
```
/verify-roadmap section-3
```

---

## Output Format

### Per-Item Output
```
─── Verifying 1.1.1: int type ───
Finding tests... tests/spec/types/primitives.ori
Running... ✓ 12 tests pass
Status: VERIFIED
```

### Section Summary
```
═══ Section 1 Complete ═══
Verified:     42 items
Needs tests:   6 items
Regressions:   2 items

Items needing attention:
- 1.1B.4: break/continue Never type — NEEDS TESTS
- 1.1B.5: ? operator Never path — NEEDS TESTS
- 1.6.1: LifetimeId type — NEEDS TESTS (not implemented)
- 1.1A.12: Duration LLVM arithmetic — REGRESSION
- 1.1A.13: Size LLVM arithmetic — REGRESSION
```

---

## Files Modified

Only modifies:
- `plans/roadmap/section-*.md` — Status and annotations

Never modifies:
- Any code files
- Any test files
- Anything outside `plans/roadmap/`
