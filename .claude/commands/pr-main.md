# PR to Main

Commit, push, create a PR to main/master, and auto-merge. Streamlines the dev → master workflow into a single command.

## Usage

```
/pr-main
```

---

## Workflow

**IMPORTANT:** Execute each step in order. Do not skip steps.

### Step 1: Check Current Branch and Status

**ACTION:** Verify we're not already on main/master:

```bash
git branch --show-current
git status
git diff --stat
```

If on `main` or `master`, STOP and inform the user they need to be on a feature/dev branch.

### Step 2: Run Commit-Push Workflow

Follow the `/commit-push` workflow:
1. Check git status and diff
2. Draft a conventional commit message
3. **Get user confirmation** before committing
4. Stage, commit, and push changes

### Step 3: Analyze Changes for PR

After pushing, analyze the commits that will be in the PR:

```bash
git log master..HEAD --oneline
git diff master..HEAD --stat
```

### Step 4: Draft PR Title and Summary

Create a PR title and summary based on the commits:

**PR Title:** Short description (under 70 chars), following the pattern:
- If single commit: Use the commit message subject
- If multiple commits: Summarize the theme (e.g., "Feature: Add X" or "Fix: Resolve Y issues")

**PR Summary:** Include:
- `## Summary` - 1-3 bullet points of key changes
- `## Test plan` - How to verify the changes

### Step 5: Present PR Details and Get Confirmation

Show the user:
1. The branch being merged (e.g., `dev` → `master`)
2. Number of commits included
3. PR title and summary

Ask: "Shall I create and merge this PR?"

**Do NOT create the PR until user confirms.**

### Step 6: Create and Auto-Merge PR

After user confirms:

```bash
gh pr create --base master --title "<title>" --body "$(cat <<'EOF'
## Summary
<bullet points>

## Test plan
<verification steps>
EOF
)"
```

Then immediately merge:

```bash
gh pr merge --merge --delete-branch=false
```

Note: `--delete-branch=false` keeps the dev branch for continued work.

### Step 7: Sync Local Master

Update local master to match remote:

```bash
git fetch origin master:master
```

Report success with the merged PR URL.

---

## Checklist

Before completing, verify:

- [ ] Confirmed not on main/master branch (Step 1)
- [ ] Changes committed and pushed (Step 2)
- [ ] PR title and summary drafted (Step 4)
- [ ] User confirmed before creating PR (Step 5)
- [ ] PR created and merged (Step 6)
- [ ] Local master synced (Step 7)

---

## Example PR

**Title:** `feat(typeck): add exhaustiveness checking for match expressions`

**Body:**
```
## Summary
- Add exhaustiveness analysis for match patterns
- Report missing variants with helpful suggestions
- Handle guard clauses correctly

## Test plan
- [x] `./test-all` passes
- [x] New tests in `tests/spec/typeck/exhaustiveness/`
```

---

## Rules

- Never run on main/master branch
- Always get user confirmation before creating the PR
- Always use `--merge` strategy (not squash or rebase) to preserve history
- Keep the feature branch after merge for continued development
- Do NOT include `Co-Authored-By` lines
