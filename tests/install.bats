#!/usr/bin/env bats
# tests/install.bats — ECL install gates for APIVR-Delta v3.2.0

load helpers.bash

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "ECL_VERSION file exists and contains a valid semver" {
  [ -f "${REPO_ROOT}/ECL_VERSION" ]
  run cat "${REPO_ROOT}/ECL_VERSION"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
}

@test "install.sh declares EIDOLON_VERSION 3.2.0" {
  grep -q 'EIDOLON_VERSION="3.2.0"' "${REPO_ROOT}/install.sh"
}

@test "install.sh declares ECL_VERSION_VAL" {
  grep -q 'ECL_VERSION_VAL="1.0"' "${REPO_ROOT}/install.sh"
}

@test "schemas directory contains ecl-envelope.v1.json" {
  [ -f "${REPO_ROOT}/schemas/ecl-envelope.v1.json" ]
}

@test "schemas directory contains all six profile schemas" {
  [ -f "${REPO_ROOT}/schemas/_base-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/apivr-completion-report-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/repair-failed-report-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/scout-report-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/spec-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/root-cause-report-profile.v1.json" ]
  [ -f "${REPO_ROOT}/schemas/reasoning-report-profile.v1.json" ]
}

@test "all vendored schemas are valid JSON" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  for f in "${REPO_ROOT}/schemas/"*.json; do
    run jq empty "$f"
    [ "$status" -eq 0 ] || { echo "Invalid JSON: $f" >&3; false; }
  done
}

@test "emit templates exist" {
  [ -f "${REPO_ROOT}/templates/apivr-completion-report.envelope.json" ]
  [ -f "${REPO_ROOT}/templates/repair-failed-report.envelope.json" ]
  [ -f "${REPO_ROOT}/templates/reasoning-request.envelope.json" ]
}

@test "inbound fixture templates exist" {
  [ -f "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json" ]
  [ -f "${REPO_ROOT}/templates/inbound/spec.envelope.fixture.json" ]
  [ -f "${REPO_ROOT}/templates/inbound/root-cause-report.envelope.fixture.json" ]
  [ -f "${REPO_ROOT}/templates/inbound/reasoning-report.envelope.fixture.json" ]
}

@test "verify-incoming skill exists (flat layout, EIIS v1.3)" {
  [ -f "${REPO_ROOT}/skills/verify-incoming.md" ]
}

@test "repair-failed-report template has trust_level high" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.constraints.trust_level' "${REPO_ROOT}/templates/repair-failed-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "high" ]]
}

@test "repair-failed-report template has ESCALATE performative" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.performative' "${REPO_ROOT}/templates/repair-failed-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "ESCALATE" ]]
}

@test "repair-failed-report template has trigger assumption" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.assumptions[0]' "${REPO_ROOT}/templates/repair-failed-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "trigger: 3-failure-same-category" ]]
}

@test "install.sh references comm field with envelope_version 1.0" {
  grep -q 'ECL_VERSION_VAL="1.0"' "${REPO_ROOT}/install.sh"
  grep -q 'envelope_version.*ECL_VERSION_VAL' "${REPO_ROOT}/install.sh"
}

@test "manifest schema has comm property" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq '.properties.comm' "${REPO_ROOT}/schemas/install.manifest.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" != "null" ]]
}
