#!/usr/bin/env bash
# Delete GHCR feature/hotfix packages whose source branch no longer exists.
#
# Live branches are listed and forward-sanitized into the same slugs the
# publish path produces; any feature/* or hotfix/* package whose slug is not in
# that set is orphaned and removed. release/stage/build-cache packages are never
# branch-scoped and are left untouched.
#
# Env:
#   ORG                organisation login (packages owner)
#   REPO_BASE          repo slug under the org, e.g. egnedata-partnerportal
#   GITHUB_REPOSITORY  owner/repo, for the branches API
#   GH_TOKEN           token with read:packages + delete:packages (org scope)
#   DRY_RUN            "true" logs intended deletions without performing them
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.github/scripts/lib-sanitize.sh
. "$SCRIPT_DIR/lib-sanitize.sh"

: "${ORG:?ORG is required}"
: "${REPO_BASE:?REPO_BASE is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
DRY_RUN="${DRY_RUN:-false}"

echo "Collecting live branches for ${GITHUB_REPOSITORY} ..."
declare -A live_feature live_hotfix
while IFS= read -r b; do
  [ -z "$b" ] && continue
  case "$b" in
    feature/*) live_feature["$(sanitize_ref "${b#feature/}")"]=1 ;;
    hotfix/*)  live_hotfix["$(sanitize_ref "${b#hotfix/}")"]=1 ;;
  esac
done < <(gh api --paginate "repos/${GITHUB_REPOSITORY}/branches" --jq '.[].name')

echo "Live feature slugs: ${!live_feature[*]:-(none)}"
echo "Live hotfix slugs:  ${!live_hotfix[*]:-(none)}"

delete_pkg() {
  local name="$1" enc
  enc="${name//\//%2F}"
  if [ "$DRY_RUN" = "true" ]; then
    echo "DRY-RUN would delete: $name"
    return 0
  fi
  echo "Deleting orphaned package: $name"
  if gh api --method DELETE "orgs/${ORG}/packages/container/${enc}"; then
    echo "  deleted"
  else
    echo "  WARN: delete failed for ${name} (continuing)"
  fi
}

count=0
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in
    "${REPO_BASE}/features/"*)
      rest="${pkg#"${REPO_BASE}/features/"}"
      slug="${rest%%/*}"
      if [ -z "${live_feature[$slug]:-}" ]; then delete_pkg "$pkg"; count=$((count + 1)); fi
      ;;
    "${REPO_BASE}/hotfix/"*)
      rest="${pkg#"${REPO_BASE}/hotfix/"}"
      slug="${rest%%/*}"
      if [ -z "${live_hotfix[$slug]:-}" ]; then delete_pkg "$pkg"; count=$((count + 1)); fi
      ;;
    *) : ;;  # release / stage / build-cache — not branch-scoped
  esac
done < <(gh api --paginate "orgs/${ORG}/packages?package_type=container" --jq '.[].name')

echo "Done. ${count} orphaned package(s) matched (DRY_RUN=${DRY_RUN})."
