#!/usr/bin/env bash
# Delete all GHCR packages produced by a single feature/hotfix branch.
# Invoked on branch deletion; the branch name arrives via DELETED_REF (env, not
# interpolated) so odd branch names cannot inject into the command line.
#
# Env:
#   ORG          organisation login (packages owner)
#   REPO_BASE    repo slug under the org, e.g. egnedata-partnerportal
#   DELETED_REF  deleted branch name, e.g. feature/foo
#   GH_TOKEN     token with delete:packages
#   DRY_RUN      "true" logs intended deletions without performing them
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.github/scripts/lib-sanitize.sh
. "$SCRIPT_DIR/lib-sanitize.sh"

: "${ORG:?ORG is required}"
: "${REPO_BASE:?REPO_BASE is required}"
: "${DELETED_REF:?DELETED_REF is required}"
DRY_RUN="${DRY_RUN:-false}"

ref="$DELETED_REF"
case "$ref" in
  feature/*) group="features"; slug="$(sanitize_ref "${ref#feature/}")" ;;
  hotfix/*)  group="hotfix";   slug="$(sanitize_ref "${ref#hotfix/}")" ;;
  *) echo "Deleted branch '${ref}' is not feature/* or hotfix/* — nothing to prune."; exit 0 ;;
esac

delete_pkg() {
  local name="$1" enc
  enc="${name//\//%2F}"
  if [ "$DRY_RUN" = "true" ]; then
    echo "DRY-RUN would delete: $name"
    return 0
  fi
  echo "Deleting package: $name"
  if gh api --method DELETE "orgs/${ORG}/packages/container/${enc}"; then
    echo "  deleted"
  else
    # 404 is expected when the branch never published this target.
    echo "  skipped (not found or already deleted)"
  fi
}

for target in server intermediate; do
  delete_pkg "${REPO_BASE}/${group}/${slug}/${target}"
done
