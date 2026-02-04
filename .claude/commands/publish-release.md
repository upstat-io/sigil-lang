# Publish Release

Prepare and publish a new release with human-curated release notes.

## Usage

```
/publish-release [version]
```

- No argument: auto-increment alpha version (e.g., 0.1.0-alpha.7 → 0.1.0-alpha.8)
- With argument: use explicit version (e.g., `0.2.0`, `0.1.0-beta.1`)

---

## Workflow

**IMPORTANT:** Execute each step in order. Do not skip steps.

### Step 1: Gather Release Information

**ACTION:** Run these commands to understand what will be released:

```bash
# Get current version
grep -E '^version\s*=' Cargo.toml | head -1

# Get the last release tag
git describe --tags --abbrev=0

# Get commits since last release (for release notes)
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges
```

### Step 2: Generate Release Notes

Analyze all commits since the last release tag and create release notes in this format:

```markdown
## What's New in vX.Y.Z

### Features
- Brief description of new feature

### Bug Fixes
- Brief description of fix

### Performance
- Brief description of optimization
```

**Guidelines for release notes:**
- Only include sections that have entries (omit empty sections)
- Use conventional commit types to categorize:
  - `feat` → Features
  - `fix` → Bug Fixes
  - `perf` → Performance
- **Exclude from release notes:**
  - `docs` → Documentation changes (not user-facing)
  - `refactor`, `chore`, `build`, `ci`, `test`, `style` → Internal changes
- Write descriptions from the user's perspective (what they get, not what you changed)
- Keep each bullet point to one line
- Skip trivial changes (typos, minor internal cleanup)
- Focus on what matters to someone reading the release: features, fixes, and performance

### Step 3: Present Release Plan to User

Show the user:
1. Current version → New version
2. The generated release notes
3. Number of commits being released

Ask: "Does this look good? Should I proceed with the release?"

**Do NOT proceed until user confirms.**

### Step 4: Run Release Script

After user confirms:

```bash
# If auto-increment (no version argument):
./scripts/release.sh

# If explicit version provided:
./scripts/release.sh <version>
```

**NOTE:** The script will prompt for confirmation. Answer 'y' to proceed.

### Step 5: Run Tests

```bash
./test-all.sh
```

If tests fail, stop and report the failure. Do not continue.

### Step 6: Commit, Tag, and Push

```bash
# Stage all changes
git add -A

# Commit with release message
git commit -m "$(cat <<'EOF'
chore: release v<VERSION>
EOF
)"

# Create tag
git tag v<VERSION>

# Push commit and tag
git push origin master --tags
```

### Step 7: Create GitHub Release with Notes

Create the GitHub release using the generated release notes:

```bash
gh release create v<VERSION> \
  --title "Ori <VERSION>" \
  --notes "$(cat <<'EOF'
<RELEASE_NOTES_HERE>
EOF
)" \
  --prerelease  # Only if alpha/beta/rc
```

**NOTE:**
- Use `--prerelease` flag for alpha, beta, or rc versions
- Omit `--prerelease` for stable releases (no pre-release suffix)
- The CI will automatically attach binaries when the tag triggers the release workflow

### Step 8: Report Success

Tell the user:
1. The release was created successfully
2. Link to the GitHub release page
3. Remind them that binaries will be built and attached automatically by CI

---

## Example Release Notes

For a release with these commits:
```
abc1234 feat(parser): add support for pattern guards
def5678 fix(typeck): resolve infinite loop in trait resolution
ghi9012 perf(llvm): optimize constant folding pass
jkl3456 docs: update installation guide
mno7890 chore(ci): update LLVM version
```

Generate (excluding docs/chore/ci commits):
```markdown
## What's New in v0.1.0-alpha.8

### Features
- Add support for pattern guards in match expressions

### Bug Fixes
- Fix infinite loop in trait resolution for circular bounds

### Performance
- Optimize constant folding pass in LLVM backend
```

---

## Checklist

Before completing, verify:

- [ ] Commits analyzed since last tag (Step 1)
- [ ] Release notes generated and categorized (Step 2)
- [ ] User confirmed release plan (Step 3)
- [ ] Version bumped via release script (Step 4)
- [ ] Tests pass (Step 5)
- [ ] Changes committed and tagged (Step 6)
- [ ] GitHub release created with notes (Step 7)
- [ ] Success reported to user (Step 8)

---

## Rules

- Always get user confirmation before making any changes
- Never skip the test step
- Never force push or use destructive git operations
- Write release notes from the user's perspective
- Focus on what matters: features, fixes, and performance
- Keep release notes concise but informative
