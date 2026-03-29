#!/usr/bin/env bash
# sync.sh — Clone missing repos and pull latest for existing ones
# Usage: .scripts/sync.sh [pull|clone|status|push]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$ROOT_DIR/.repos"
ACTION="${1:-pull}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: .repos manifest not found at $MANIFEST"
  exit 1
fi

while IFS= read -r line; do
  # Skip comments and blank lines
  [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue

  dir=$(echo "$line" | awk '{print $1}')
  repo=$(echo "$line" | awk '{print $2}')

  case "$ACTION" in
    clone)
      if [[ ! -d "$ROOT_DIR/$dir" ]]; then
        echo "Cloning $repo -> $dir"
        git clone "git@github.com:$repo.git" "$ROOT_DIR/$dir"
      else
        echo "Skip $dir (already exists)"
      fi
      ;;
    pull)
      if [[ -d "$ROOT_DIR/$dir/.git" ]]; then
        echo "Pulling $dir..."
        git -C "$ROOT_DIR/$dir" pull --ff-only 2>&1 || echo "  Warning: pull failed for $dir"
      else
        echo "Cloning $repo -> $dir"
        git clone "git@github.com:$repo.git" "$ROOT_DIR/$dir"
      fi
      ;;
    status)
      if [[ -d "$ROOT_DIR/$dir/.git" ]]; then
        changes=$(git -C "$ROOT_DIR/$dir" status --porcelain)
        branch=$(git -C "$ROOT_DIR/$dir" branch --show-current)
        ahead=$(git -C "$ROOT_DIR/$dir" rev-list --count @{upstream}..HEAD 2>/dev/null || echo "?")
        if [[ -n "$changes" || "$ahead" != "0" ]]; then
          echo "[$dir] branch=$branch ahead=$ahead dirty=$(echo "$changes" | wc -l | tr -d ' ')"
        else
          echo "[$dir] clean"
        fi
      else
        echo "[$dir] NOT CLONED"
      fi
      ;;
    push)
      if [[ -d "$ROOT_DIR/$dir/.git" ]]; then
        changes=$(git -C "$ROOT_DIR/$dir" status --porcelain)
        if [[ -n "$changes" ]]; then
          echo "Committing & pushing $dir..."
          git -C "$ROOT_DIR/$dir" add -A
          git -C "$ROOT_DIR/$dir" commit -m "${COMMIT_MSG:-Auto-commit local changes}"
          git -C "$ROOT_DIR/$dir" push
        else
          echo "[$dir] clean, skipping"
        fi
      fi
      ;;
    *)
      echo "Usage: sync.sh [clone|pull|status|push]"
      exit 1
      ;;
  esac
done < "$MANIFEST"
