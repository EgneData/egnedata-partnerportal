#!/usr/bin/env bash
# Canonical branch-slug sanitizer for GHCR package paths.
#
# MUST stay byte-for-byte equivalent to the sanitize() in
# .github/actions/docker-publish/compute-image-ref.sh — that is the path that
# produces the package names the prune scripts reverse-match against. If the
# publishing sanitizer changes, change this one in the same commit.
sanitize_ref() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9._-]/-/g' \
    | sed 's/[._-][._-]*/-/g' \
    | sed 's/^[._-]*//' \
    | sed 's/[._-]*$//' \
    | cut -c1-100
}
