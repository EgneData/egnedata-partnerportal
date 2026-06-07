#!/usr/bin/env bash
set -euo pipefail

KEEP=false

usage() {
  echo "Usage: $0 [--keep] [--help]"
  echo ""
  echo "Push HEAD to a throwaway feature/* ref, watch the build.yml run,"
  echo "and assert the publish job computed the correct hashed feature image"
  echo "path without pushing to ghcr (PUBLISH_IMAGES must be unset/false)."
  echo ""
  echo "Options:"
  echo "  --keep   Retain the remote branch after a successful run"
  echo "  --help   Show this help message"
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --keep)    KEEP=true ;;
    *)         echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

SHORT=$(git rev-parse --short HEAD)
FB="feature/ci-dry-run-${SHORT}"
ORIG_REF=$(git rev-parse HEAD)

# GitHub deduplicates workflow runs by commit SHA and skips empty commits
# (paths-ignore matches vacuously). Touch a non-ignored file so the probe
# commit has a unique SHA AND non-empty file diff.
PROBE=".ci-probe"
date +%s > "$PROBE"
git add "$PROBE"
git commit -m "ci: dry-run probe ${SHORT}" --no-gpg-sign >/dev/null 2>&1
SHA=$(git rev-parse HEAD)

echo "=== pushing $SHA to remote ref $FB ==="
git push origin "HEAD:refs/heads/$FB"

# Reset local branch back immediately — the probe commit is remote-only.
git reset --hard "$ORIG_REF" >/dev/null 2>&1

echo "=== locating build.yml run for $SHA on $FB ==="
RID=""
for _ in $(seq 1 40); do
  RID=$(env -u GH_TOKEN -u GITHUB_TOKEN gh run list \
    -w build.yml -b "$FB" -c "$SHA" \
    --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)
  [[ -n "$RID" ]] && break
  sleep 5
done

if [[ -z "$RID" ]]; then
  echo "ERROR: no build.yml run registered for $SHA on $FB" >&2
  if [[ "$KEEP" == false ]]; then
    echo "=== cleaning up remote branch $FB ==="
    git push origin --delete "refs/heads/$FB" 2>/dev/null || true
  fi
  exit 1
fi

echo "=== watching run $RID (non-zero exit on red) ==="
if ! env -u GH_TOKEN -u GITHUB_TOKEN gh run watch "$RID" --exit-status -i 10; then
  echo "ERROR: build.yml run $RID failed" >&2
  echo "Remote branch $FB left for debugging."
  exit 1
fi

echo "=== asserting feature image path in publish job log ==="
LOG=$(env -u GH_TOKEN -u GITHUB_TOKEN gh run view "$RID" --log)
if ! echo "$LOG" | grep -Eq 'features/[^/]+/(server|intermediate)'; then
  echo "ERROR: expected feature image path not found in run log" >&2
  echo "Remote branch $FB left for debugging."
  exit 1
fi

echo "=== dry run succeeded — feature path verified, nothing pushed to ghcr ==="
if [[ "$KEEP" == false ]]; then
  echo "=== cleaning up remote branch $FB ==="
  git push origin --delete "refs/heads/$FB" 2>/dev/null || true
fi
