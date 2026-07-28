# Catppuccin TPM Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make TPM discover Catppuccin while retaining conditional loading on modern tmux.

**Architecture:** Declare Catppuccin as an unconditional top-level TPM plugin so TPM's static parser sees it. Keep the existing `@modern_tmux` guards around runtime loading and status configuration.

**Tech Stack:** tmux configuration, Bash/AWK verification, Git

## Global Constraints

- Keep `catppuccin/tmux#v2.3.0` pinned at the existing version.
- Do not change prefix keys, terminal flow control, resurrect, continuum, or plugin installation state.
- Keep Catppuccin runtime loading conditional on `@modern_tmux`.

---

### Task 1: Expose Catppuccin to TPM Static Discovery

**Files:**
- Modify: `tmux/.tmux.conf`
- Verify: `~/.tmux.conf`

**Interfaces:**
- Consumes: TPM's top-level `set -g @plugin` configuration convention.
- Produces: one statically discoverable `catppuccin/tmux#v2.3.0` entry.

- [ ] **Step 1: Run the failing discovery test**

```bash
awk '/^[ \t]*set(-option)? +-g +@plugin/ { gsub(/'"'"'/, ""); gsub(/"/, ""); print $4 }' tmux/.tmux.conf | grep -Fx 'catppuccin/tmux#v2.3.0'
```

Expected: exit 1 because the Catppuccin declaration is hidden inside a quoted `if-shell` command.

- [ ] **Step 2: Make the minimal configuration change**

Replace the conditional plugin declaration with this top-level line:

```tmux
set -g @plugin "catppuccin/tmux#v2.3.0"
```

Do not alter the later conditional `run-shell` or status configuration blocks.

- [ ] **Step 3: Run the discovery test again**

```bash
test "$(awk '/^[ \t]*set(-option)? +-g +@plugin/ { gsub(/'"'"'/, ""); gsub(/"/, ""); print $4 }' tmux/.tmux.conf | grep -Fxc 'catppuccin/tmux#v2.3.0')" -eq 1
```

Expected: exit 0.

- [ ] **Step 4: Verify guards and installed-config synchronization**

```bash
rg -n '@modern_tmux|catppuccin\.tmux|catppuccin_status_session' tmux/.tmux.conf
cmp -s tmux/.tmux.conf ~/.tmux.conf
git diff --check
```

Expected: runtime guards remain, the installed config matches the source, and the diff has no whitespace errors.

- [ ] **Step 5: Commit and publish**

```bash
git add tmux/.tmux.conf docs/superpowers/plans/2026-07-28-catppuccin-tpm-discovery.md
git commit -m "fix tmux catppuccin TPM discovery"
git push origin main
```
