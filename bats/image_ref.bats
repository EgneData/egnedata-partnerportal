#!/usr/bin/env bats

setup() {
  export BATS_LIB_PATH=/usr/local/lib/bats
  bats_load_library bats-support
  bats_load_library bats-assert
  H=.github/actions/docker-publish/compute-image-ref.sh
  B=egnedata/egnedata-partnerportal
}

@test "release path" {
  run bash "$H" RELEASE main server "$B"
  assert_success
  assert_output "$B/release/server"
}

@test "stage path (intermediate)" {
  run bash "$H" STAGE develop intermediate "$B"
  assert_output "$B/stage/intermediate"
}

@test "feature path is lowercased and prefix-stripped" {
  run bash "$H" FEATURE feature/Add-Login server "$B"
  assert_output "$B/features/add-login/server"
  refute_output --partial "feature/feature"
}

@test "hotfix path uses its own group" {
  run bash "$H" HOTFIX hotfix/CVE-123 server "$B"
  assert_output "$B/hotfix/cve-123/server"
}

@test "non-publishing build-types fail" {
  run bash "$H" OTHER whatever server "$B"
  assert_failure
}
