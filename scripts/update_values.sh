#!/usr/bin/env bash
# Usage: ./update_values.sh <git_repo_url_with_creds> <new_image>
set -euo pipefail
REPO_URL="$1"
NEW_IMAGE="$2"
TMP_DIR=$(mktemp -d)

echo "Cloning repo: $REPO_URL"
if ! git clone "$REPO_URL" "$TMP_DIR"; then
  echo "Failed to clone $REPO_URL" >&2
  exit 2
fi

cd "$TMP_DIR"
VALUES_FILE="values.yaml"
if [ ! -f "$VALUES_FILE" ]; then
  echo "values.yaml not found in repo root, searching..."
  VALUES_FILE=$(find . -maxdepth 3 -type f -name values.yaml | head -n1 || true)
  if [ -z "$VALUES_FILE" ]; then
    echo "No values.yaml found" >&2
    exit 3
  fi
fi

echo "Updating image in $VALUES_FILE to $NEW_IMAGE"
# Replace a line that starts with 'repository:' or 'image:' depending on layout.
# This uses a simple heuristic — adjust to your repo structure.

grep -q "repository:" "$VALUES_FILE" && sed -i "s|^\s*repository:.*|  repository: ${NEW_IMAGE%%:*}|" "$VALUES_FILE" || true
grep -q "tag:" "$VALUES_FILE" && sed -i "s|^\s*tag:.*|  tag: ${NEW_IMAGE##*:}|" "$VALUES_FILE" || true

# Fallback: try to replace a full image line if present
sed -i "s|\(image:\s*\).*|\1${NEW_IMAGE}|" "$VALUES_FILE" || true

# Commit + push
git add "$VALUES_FILE"
if git diff --quiet --cached; then
  echo "No changes to commit"
  exit 0
fi

git commit -m "ci: update image to ${NEW_IMAGE} [ci skip]"
# Push back to origin (credentials must be included in the repo URL passed to the script)
git push origin HEAD:main

echo "Updated and pushed $VALUES_FILE"
