# Commit and Push All Changes

Stage, commit, and push all changes to the remote repository using conventional commit format.

## Usage

```
/commit-push
```

---

## Workflow

**IMPORTANT:** Execute each step in order. Do not skip steps.

### Step 1: Run /sync-webpage (MANDATORY)

**ACTION:** Use the Skill tool to invoke `sync-webpage` BEFORE doing anything else.

```
Skill(skill: "sync-webpage")
```

This ensures the website roadmap is synchronized with the spec before committing.

Wait for sync-webpage to complete before proceeding.

### Step 2: Check Git Status

**ACTION:** Run these commands to see what will be committed:

```bash
git status
git diff --stat
```

### Step 3: Analyze and Draft Commit Message

Review the changes and create a commit message following conventional commit format:

```
<type>(<scope>): <description>

<body>
```

**Valid types:**
| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Code style changes (formatting, etc) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Changes to build system or dependencies |
| `ci` | Changes to CI configuration |
| `chore` | Other changes that don't modify src or test files |
| `revert` | Reverts a previous commit |

**Scope** is optional. Use the primary module affected (e.g., `typeck`, `parser`, `llvm`).

### Step 4: Present to User and Get Confirmation

Show the user:
1. Summary of files changed
2. The proposed commit message

Ask: "Shall I proceed with this commit?"

**Do NOT commit until user confirms.**

### Step 5: Commit

After user confirms:

```bash
git add -A
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

### Step 6: Push

```bash
git push
```

Report success or any errors.

---

## Checklist

Before completing, verify:

- [ ] `/sync-webpage` was run FIRST (Step 1)
- [ ] `git status` was checked (Step 2)
- [ ] Commit message follows conventional format (Step 3)
- [ ] User confirmed before committing (Step 4)
- [ ] Changes committed (Step 5)
- [ ] Changes pushed (Step 6)

---

## Example Commit Message

```
perf(typeck): optimize line lookup and hash map usage

- Add LineOffsetTable for O(log n) line lookups instead of O(n)
- Switch to FxHashMap/FxHashSet in type checker components
- Add index for O(1) associated type lookups
- Optimize diagnostic queue sorting

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Rules

- Always run `/sync-webpage` first — this is not optional
- Always run `git status` before committing
- Always get user confirmation before committing
- Never force push or use destructive git operations
- Keep the first line of commit message under 72 characters
- Include `Co-Authored-By` line when Claude contributed
