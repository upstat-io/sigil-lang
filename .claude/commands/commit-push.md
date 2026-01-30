# Commit and Push All Changes

Stage, commit, and push all changes to the remote repository using conventional commit format.

## Usage

```
/commit-push
```

---

## Workflow

### Step 1: Check Status

Run `git status` and `git diff --stat` to understand what changes will be committed.

### Step 2: Analyze Changes

Review the changes to determine:
- The primary type of change (feat, fix, refactor, perf, docs, test, chore, etc.)
- An optional scope (e.g., typeck, diagnostic, parser)
- A concise description of what changed

### Step 3: Draft Commit Message

Create a commit message following conventional commit format:

```
<type>(<scope>): <description>

<body>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

**Valid types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, semicolons, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or correcting tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

**Scope** is optional but recommended. Use the primary module/crate affected (e.g., `typeck`, `diagnostic`, `parser`, `eval`, `llvm`).

### Step 4: Present to User

Show the user:
1. Summary of files changed
2. The proposed commit message
3. Ask for confirmation before committing

### Step 5: Commit and Push

If user confirms:
1. Stage all changes: `git add -A`
2. Commit with the message (use HEREDOC for proper formatting)
3. Push to remote: `git push`

Report success or any errors.

---

## Example

For performance improvements to the type checker:

```
perf(typeck): optimize line lookup and hash map usage

- Add LineOffsetTable for O(log n) line lookups instead of O(n)
- Switch to FxHashMap/FxHashSet in type checker components
- Add index for O(1) associated type lookups
- Optimize diagnostic queue sorting

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Notes

- Always run `git status` first to see what will be committed
- Never force push or use destructive git operations
- The commit message body should summarize key changes
- Keep the first line under 72 characters
