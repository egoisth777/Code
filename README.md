---
aliases: []
tags: []
icon:
date-created: 2025-04-07-01:30:48
date-modified: 2026-03-27
---

# Code

> Parent directory for all pieces of code that I created.

## Structure

Flat layout — each child is an independent git repo listed in `.repos`.
No submodules. Sync via `.scripts/sync.sh`.

```bash
.scripts/sync.sh clone    # Clone all missing repos
.scripts/sync.sh pull     # Pull latest for all repos
.scripts/sync.sh status   # Check status across all repos
COMMIT_MSG="msg" .scripts/sync.sh push  # Commit & push all dirty repos
```

PowerShell: `.scripts/sync.ps1 -Action pull`
