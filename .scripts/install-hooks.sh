#!/usr/bin/env bash
# Install git hooks for the parent Code repo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$ROOT_DIR/.git/hooks"

# post-merge hook: auto-pull child repos after git pull
cat > "$HOOKS_DIR/post-merge" << 'HOOK'
#!/usr/bin/env bash
echo "Running post-merge: syncing child repos..."
"$(git rev-parse --show-toplevel)/.scripts/sync.sh" pull
HOOK
chmod +x "$HOOKS_DIR/post-merge"

echo "Hooks installed."
