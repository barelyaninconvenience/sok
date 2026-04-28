#!/usr/bin/env bash
# Install pre-commit + commit-msg OPSEC sweep hooks into all public Clay repos
# Run from anywhere; uses absolute paths
#
# Safe to run multiple times (idempotent — overwrites existing hooks with current version)

set -e

HOOK_DIR="C:/Users/shelc/Documents/Journal/Projects/scripts/git-hooks"
HOOK_SOURCE="$HOOK_DIR/pre-commit-opsec-sweep"
MSG_HOOK_SOURCE="$HOOK_DIR/commit-msg-opsec-sweep"
PUSH_HOOK_SOURCE="$HOOK_DIR/pre-push-opsec-sweep"

# Public-eligible repos to install the hook into
REPOS=(
    "C:/Users/shelc/Documents/Journal/Projects/substrate-thesis-companion"
    "C:/Users/shelc/Documents/Journal/Projects/structured-data-crawler-substrate"
    "C:/Users/shelc/Documents/Journal/Projects/scripts"
    "C:/Users/shelc/Documents/Journal/Projects/BS_IT_WGU"
    "C:/Users/shelc/Documents/Journal/Projects/matlab-radar-adaptive-waveform"
)

if [ ! -f "$HOOK_SOURCE" ]; then
    echo "ERROR: hook source file not found at $HOOK_SOURCE"
    exit 1
fi

INSTALLED=0
SKIPPED=0

for repo in "${REPOS[@]}"; do
    if [ ! -d "$repo/.git" ]; then
        echo "SKIP: $repo (not a git repository)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    HOOK_DEST="$repo/.git/hooks/pre-commit"
    cp "$HOOK_SOURCE" "$HOOK_DEST"
    chmod +x "$HOOK_DEST" 2>/dev/null || true
    echo "INSTALLED: $repo/.git/hooks/pre-commit"

    MSG_HOOK_DEST="$repo/.git/hooks/commit-msg"
    cp "$MSG_HOOK_SOURCE" "$MSG_HOOK_DEST"
    chmod +x "$MSG_HOOK_DEST" 2>/dev/null || true
    echo "INSTALLED: $repo/.git/hooks/commit-msg"

    PUSH_HOOK_DEST="$repo/.git/hooks/pre-push"
    cp "$PUSH_HOOK_SOURCE" "$PUSH_HOOK_DEST"
    chmod +x "$PUSH_HOOK_DEST" 2>/dev/null || true
    echo "INSTALLED: $repo/.git/hooks/pre-push"

    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "Installation summary:"
echo "  Installed: $INSTALLED"
echo "  Skipped:   $SKIPPED"
echo ""
echo "To test on a specific repo:"
echo "  cd <repo>"
echo "  echo 'CLAY_PC test' > test_leak.txt"
echo "  git add test_leak.txt"
echo "  git commit -m 'test commit'  # should be BLOCKED"
echo ""
echo "To override hook (legitimate edge case):"
echo "  git commit --no-verify -m 'commit message'"
echo ""
echo "To uninstall a hook from a single repo:"
echo "  rm <repo>/.git/hooks/pre-commit"
