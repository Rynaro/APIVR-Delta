#!/usr/bin/env bash
# tests/helpers.bash — shared test helpers for APIVR-Delta ECL bats suite

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMAS_DIR="${REPO_ROOT}/schemas"
TEMPLATES_DIR="${REPO_ROOT}/templates"

# setup_envelope_fixture <kind> <from_eidolon> <version>
# Creates a temporary directory with a minimal payload + valid envelope.
# Sets: FIXTURE_DIR, PAYLOAD_PATH, ENVELOPE_PATH, PAYLOAD_SHA256
setup_envelope_fixture() {
  local kind="$1"
  local from_eidolon="${2:-apivr}"
  local eidolon_version="${3:-3.1.0}"

  FIXTURE_DIR="$(mktemp -d)"

  # Minimal payload file
  PAYLOAD_PATH="${FIXTURE_DIR}/payload.md"
  printf 'eidolon: %s\nversion: %s\nkind: %s\nstatus: completed\ncreated_at: 2026-05-08T00:00:00Z\n' \
    "$from_eidolon" "$eidolon_version" "$kind" > "${PAYLOAD_PATH}"

  # Compute SHA-256
  if command -v shasum &>/dev/null; then
    PAYLOAD_SHA256="$(shasum -a 256 "${PAYLOAD_PATH}" | awk '{print $1}')"
  elif command -v sha256sum &>/dev/null; then
    PAYLOAD_SHA256="$(sha256sum "${PAYLOAD_PATH}" | awk '{print $1}')"
  else
    PAYLOAD_SHA256="0000000000000000000000000000000000000000000000000000000000000000"
  fi

  PAYLOAD_SIZE="$(wc -c < "${PAYLOAD_PATH}" | tr -d ' ')"

  ENVELOPE_PATH="${FIXTURE_DIR}/payload.envelope.json"
  printf '%s' "{
  \"envelope_version\": \"1.0\",
  \"message_id\": \"01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1\",
  \"thread_id\":  \"01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1\",
  \"parent_id\":  null,
  \"from\": { \"eidolon\": \"${from_eidolon}\", \"version\": \"${eidolon_version}\" },
  \"to\":   { \"eidolon\": \"apivr\",            \"version\": \"3.1.0\" },
  \"performative\": \"PROPOSE\",
  \"edge_origin\": \"roster\",
  \"objective\": \"Test fixture envelope for ${kind}.\",
  \"artifact\": {
    \"kind\": \"${kind}\",
    \"schema_version\": \"1.0\",
    \"path\": \"${FIXTURE_DIR}/payload.md\",
    \"sha256\": \"${PAYLOAD_SHA256}\",
    \"size_bytes\": ${PAYLOAD_SIZE}
  },
  \"integrity\": {
    \"method\": \"sha256\",
    \"value\": \"${PAYLOAD_SHA256}\"
  },
  \"trace\": {
    \"ts\": \"2026-05-08T00:00:00Z\",
    \"host\": \"claude-code\",
    \"model\": \"claude-sonnet-4-6\",
    \"tier\": \"standard\"
  }
}" > "${ENVELOPE_PATH}"
}

# assert_envelope_valid <envelope_path>
# Validates envelope is parseable JSON with required fields present.
assert_envelope_valid() {
  local envelope_path="$1"
  if ! command -v jq &>/dev/null; then
    echo "SKIP: jq not available" >&3
    return 0
  fi
  jq empty "${envelope_path}" || return 1
  local version
  version="$(jq -r '.envelope_version' "${envelope_path}")"
  [[ "$version" == "1.0" ]] || { echo "envelope_version mismatch: ${version}" >&3; return 1; }
  return 0
}

# sha256_of <path>
sha256_of() {
  local f="$1"
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$f" | awk '{print $1}'
  else
    echo "0000000000000000000000000000000000000000000000000000000000000000"
  fi
}

# teardown_fixture
teardown_fixture() {
  [[ -n "${FIXTURE_DIR:-}" && -d "${FIXTURE_DIR}" ]] && rm -rf "${FIXTURE_DIR}"
}
