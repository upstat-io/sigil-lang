---
paths:
  - "plans/roadmap/**"
  - ".claude/commands/*-roadmap.md"
  - ".claude/skills/continue-roadmap/**"
---

# Roadmap Rules

## No Emojis

**Never use emojis in roadmap files, roadmap commands, or roadmap skills.** Use plain text markers instead:

| Instead of | Use |
|------------|-----|
| Checkmark emoji | `[done]` |
| Yellow circle emoji | `[partial]` |
| Red X emoji | `[todo]` |
| Warning emoji | `WARNING:` or omit (the label like `BUG FOUND` is already clear) |
| Search/magnifying glass emoji | Omit (the label like `WEAK TESTS` is already clear) |
| Any status emoji | `[approved]`, `[draft]`, `[missing]`, etc. |

Status annotations use **uppercase labels** (e.g., `REGRESSION`, `WRONG TEST`, `STALE TEST`, `BUG FOUND`, `NEEDS TESTS`, `WEAK TESTS`) — the label itself conveys severity without emoji decoration.
