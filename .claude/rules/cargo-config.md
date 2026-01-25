---
paths: **Cargo.toml**
---

# Cargo Configuration Protection

**Do NOT edit any Cargo.toml files without explicit user permission.**

The workspace and crate Cargo.toml files contain carefully configured:
- Workspace members and dependencies
- Lint configurations (strict by design)
- Build settings

Always ask the user before making any changes to Cargo configuration.
