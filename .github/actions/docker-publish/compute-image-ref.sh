#!/bin/sh
# Usage: compute-image-ref.sh <build-type> <ref> <target> <repo-base>
# Prints the lowercased image path (no registry, no tag).
# Exits 1 for non-publishing build-types (PULL_REQUEST, DEPENDABOT, OTHER).
set -eu

build_type="$1"
ref="$2"
target="$3"
repo_base="$4"

# Hash of the original ref ensures two branches that sanitize identically stay unique.
refhash=$(printf '%s' "$ref" | sha1sum | cut -c1-7)

# Strip prefix, lowercase, replace invalid chars, collapse repeated separators,
# trim leading/trailing separators, truncate to 100 chars.
sanitize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9._-]/-/g' \
    | sed 's/[._-][._-]*/-/g' \
    | sed 's/^[._-]*//' \
    | sed 's/[._-]*$//' \
    | cut -c1-100
}

case "$build_type" in
  RELEASE)
    result="${repo_base}/release/${target}"
    ;;
  STAGE)
    result="${repo_base}/stage/${target}"
    ;;
  FEATURE)
    san=$(sanitize "${ref#feature/}")
    result="${repo_base}/features/${san}-${refhash}/${target}"
    ;;
  HOTFIX)
    san=$(sanitize "${ref#hotfix/}")
    result="${repo_base}/hotfix/${san}-${refhash}/${target}"
    ;;
  PULL_REQUEST|DEPENDABOT|OTHER)
    exit 1
    ;;
  *)
    printf 'Unknown build-type: %s\n' "$build_type" >&2
    exit 1
    ;;
esac

# ghcr requires fully lowercase image refs.
printf '%s\n' "$result" | tr '[:upper:]' '[:lower:]'
