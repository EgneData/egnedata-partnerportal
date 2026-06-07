#!/usr/bin/env bats
# Contract tests for bin/release_to_main.sh and .github/workflows/release-to-main.yml.
# Validates interface and the load-bearing invariant that no git tags are created.

BATS_LIB_PATH=/usr/local/lib/bats
bats_load_library "bats-support"
bats_load_library "bats-assert"

SCRIPT="bin/release_to_main.sh"
WORKFLOW=".github/workflows/release-to-main.yml"

@test "script is executable" {
  [ -x "$SCRIPT" ]
}

@test "script contains no git-tag commands" {
  run grep -E '^\s*git tag' "$SCRIPT"
  assert_failure
}

@test "script uses --ff-only merge" {
  run grep -- '--ff-only' "$SCRIPT"
  assert_success
}

@test "script rejects unknown option" {
  run bash "$SCRIPT" --unknown-option
  assert_failure
}

@test "script supports --dry-run" {
  run grep -- '--dry-run' "$SCRIPT"
  assert_success
}

@test "script supports --yes" {
  run grep -- '--yes' "$SCRIPT"
  assert_success
}

@test "script --help exits successfully" {
  run bash "$SCRIPT" --help
  assert_success
}

@test "workflow is workflow_dispatch" {
  run grep 'workflow_dispatch' "$WORKFLOW"
  assert_success
}

@test "workflow does not fan out to build.yml" {
  run grep 'gh workflow run build.yml' "$WORKFLOW"
  assert_failure
}

@test "workflow contains no git-tag commands" {
  run grep -E '^\s*git tag' "$WORKFLOW"
  assert_failure
}
