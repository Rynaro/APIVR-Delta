#!/usr/bin/env bash
set -euo pipefail

EIDOLON_NAME="apivr"
EIDOLON_SLUG="apivr"
EIDOLON_VERSION="3.2.0"
METHODOLOGY="APIVR-Δ"
ECL_VERSION_VAL="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Legacy v1.2-era artefacts swept by cleanup_legacy_v1_2 on upgrade.
# Strategy A (hardcoded per-Eidolon list) — see install-cleanup-v1.3.1-spec §2.
LEGACY_SPEC_FILES=( "apivr.md" )
LEGACY_SKILL_DIRS=( \
  "context-engineering" \
  "failure-recovery" \
  "memory-management" \
  "methodology" \
  "verify-incoming" \
)

# --- defaults ---
TARGET="./.eidolons/${EIDOLON_NAME}"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false
SHARED_DISPATCH=false

# --- helpers ---
log()  { echo "  $*"; }
act()  { echo "  [write] $*"; }
skip() { echo "  [skip]  $*"; }
warn() { echo "  [warn]  $*" >&2; }
die()  { echo "  [error] $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Install the ${METHODOLOGY} v${EIDOLON_VERSION} Eidolon into a consumer project.

Options:
  --target DIR            Target install dir (default: ${TARGET})
  --hosts LIST            claude-code,copilot,cursor,opencode,codex,all (default: auto)
  --shared-dispatch       Compose marker-bounded section in root AGENTS.md /
                          CLAUDE.md / .github/copilot-instructions.md (opt-in).
  --no-shared-dispatch    Skip root dispatch files (default).
  --force                 Overwrite existing install
  --dry-run               Print actions, no writes
  --non-interactive       No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only         Only emit install.manifest.json
  --version               Print Eidolon version
  -h, --help              Show help
EOF
}

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)               TARGET="$2"; shift 2 ;;
    --hosts)                HOSTS="$2"; shift 2 ;;
    --shared-dispatch)      SHARED_DISPATCH=true; shift ;;
    --no-shared-dispatch)   SHARED_DISPATCH=false; shift ;;
    --force)                FORCE=true; shift ;;
    --dry-run)              DRY_RUN=true; shift ;;
    --non-interactive)      NON_INTERACTIVE=true; shift ;;
    --manifest-only)        MANIFEST_ONLY=true; shift ;;
    --version)              echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)              usage; exit 0 ;;
    *)                      echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# --- host detection ---
# EIIS v1.1 §4.5 — `.codex/` is the strongest Codex signal. Root AGENTS.md
# alone (no `.github/`, no `.codex/`) also indicates Codex. AGENTS.md is
# co-owned by `copilot` and `codex` when both their signals are present.
detect_hosts() {
  local detected=()
  [[ -f "CLAUDE.md" || -d ".claude" ]] && detected+=("claude-code")
  [[ -d ".github" ]]                    && detected+=("copilot")
  [[ -d ".cursor" || -f ".cursorrules" ]] && detected+=("cursor")
  [[ -d ".opencode" ]]                  && detected+=("opencode")
  # Codex signals (EIIS v1.1 §4.1.0, §4.5):
  #   - `.codex/` directory is the strongest, definitive Codex-only signal.
  #   - root `AGENTS.md` is the Codex primary instruction surface; co-owned
  #     with `copilot`. Detect Codex whenever AGENTS.md is present, unless
  #     `.codex/` already added it.
  if [[ -d ".codex" ]]; then
    detected+=("codex")
  elif [[ -f "AGENTS.md" ]]; then
    detected+=("codex")
  fi
  if [[ ${#detected[@]} -eq 0 ]]; then
    printf ""
  else
    printf "%s\n" "${detected[@]}"
  fi
}

if [[ "$HOSTS" == "auto" ]]; then
  # `paste -sd, -` portable across BSD (macOS) and GNU. Empty stdin yields ""
  # which we coerce to "none" below.
  detected_list="$(detect_hosts | paste -sd, - || true)"
  HOSTS="${detected_list:-none}"
  log "Auto-detected hosts: ${HOSTS}"
elif [[ "$HOSTS" == "all" ]]; then
  HOSTS="claude-code,copilot,cursor,opencode,codex"
fi

# Relative form of TARGET for @-references and manifest paths (strips leading ./)
TARGET_REL="${TARGET#./}"

# --- idempotency check ---
MANIFEST_PATH="${TARGET}/install.manifest.json"
if [[ -f "${MANIFEST_PATH}" && "$FORCE" != "true" ]]; then
  EXISTING_VER="$(grep -o '"version":"[^"]*"' "${MANIFEST_PATH}" 2>/dev/null | cut -d'"' -f4 || echo "unknown")"
  if [[ "$EXISTING_VER" == "$EIDOLON_VERSION" ]]; then
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      log "Already at v${EIDOLON_VERSION}. Pass --force to reinstall."
      exit 0
    fi
    read -rp "  Already installed at v${EXISTING_VER}. Reinstall? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Aborted."; exit 0; }
  else
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      die "Existing install v${EXISTING_VER} at ${TARGET}. Pass --force to upgrade."
    fi
    read -rp "  Existing install v${EXISTING_VER} found. Upgrade to v${EIDOLON_VERSION}? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Aborted."; exit 0; }
  fi
fi

# --- sha256 helper ---
sha256_file() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "00000000000000000000000000000000"
  fi
}

# --- dry-run wrapper ---
do_mkdir() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

do_cp() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    act "[dry-run] cp $src → $dst"
  else
    cp "$src" "$dst"
    act "$dst"
  fi
}

do_cp_r() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    act "[dry-run] cp -r $src/ → $dst/"
  else
    cp -r "$src/." "$dst/"
    act "$dst/ (directory)"
  fi
}

do_write() {
  local path="$1" content="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    act "[dry-run] write $path"
  else
    printf '%s' "$content" > "$path"
    act "$path"
  fi
}

do_append() {
  local path="$1" content="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    act "[dry-run] append → $path"
  else
    printf '%s' "$content" >> "$path"
    act "$path (appended)"
  fi
}

# upsert_eidolon_block <file> <content>
#
# Owns a marker-bounded region in a composable dispatch file. Rewrites the
# body in place when markers already exist; appends a new block otherwise.
# Cleans up any pre-existing symlink at the target.
upsert_eidolon_block() {
  local dst="$1" content="$2"
  local start="<!-- eidolon:${EIDOLON_NAME} start -->"
  local end="<!-- eidolon:${EIDOLON_NAME} end -->"

  if [[ "$DRY_RUN" == "true" ]]; then
    local action="append"
    [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null && action="rewrite"
    act "[dry-run] ${action} eidolon:${EIDOLON_NAME} block in ${dst}"
    return
  fi

  mkdir -p "$(dirname "$dst")" 2>/dev/null || true
  [[ -L "$dst" ]] && rm -f "$dst"

  local content_file tmp
  content_file="$(mktemp)"
  printf '%s\n' "$content" > "$content_file"

  if [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null; then
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" -v cf="$content_file" '
      BEGIN { in_block = 0 }
      $0 == start {
        print start
        while ((getline line < cf) > 0) print line
        close(cf)
        in_block = 1
        next
      }
      $0 == end {
        print end
        in_block = 0
        next
      }
      !in_block { print }
    ' "$dst" > "$tmp"
    mv "$tmp" "$dst"
    act "${dst} (rewrote eidolon:${EIDOLON_NAME} block)"
  elif [[ -f "$dst" ]]; then
    { printf '\n%s\n' "$start"; cat "$content_file"; printf '%s\n' "$end"; } >> "$dst"
    act "${dst} (appended eidolon:${EIDOLON_NAME} block)"
  else
    { printf '%s\n' "$start"; cat "$content_file"; printf '%s\n' "$end"; } > "$dst"
    act "${dst} (created with eidolon:${EIDOLON_NAME} block)"
  fi

  rm -f "$content_file"
}

# cleanup_legacy_v1_2 <target>
#
# Sweep legacy v1.2-era artefacts left behind by prior installs.
# Called exactly once, early in the install sequence, BEFORE any new content
# is written under <target>. Idempotent: no-op when no legacy file exists.
#
# Reads two top-of-file arrays:
#   LEGACY_SPEC_FILES  — basenames to rm -f at "<target>/<basename>"
#   LEGACY_SKILL_DIRS  — skill names to rm -rf at "<target>/skills/<name>"
#
# Both arrays are declared per-Eidolon and MAY be empty (in which case
# the corresponding loop is a no-op). Never reads/writes outside <target>.
cleanup_legacy_v1_2() {
  local target="$1"
  local legacy
  local legacy_skill_dir

  if [ -z "${target}" ] || [ ! -d "${target}" ]; then
    return 0
  fi

  # Sweep legacy spec filenames (e.g. apivr.md)
  for legacy in "${LEGACY_SPEC_FILES[@]}"; do
    if [ -n "${legacy}" ] && [ -f "${target}/${legacy}" ]; then
      rm -f "${target}/${legacy}"
      log "[cleanup] swept legacy spec file: ${target}/${legacy}"
    fi
  done

  # Sweep legacy subdir-style skills (e.g. skills/methodology/SKILL.md)
  for legacy_skill_dir in "${LEGACY_SKILL_DIRS[@]}"; do
    if [ -n "${legacy_skill_dir}" ] && [ -d "${target}/skills/${legacy_skill_dir}" ]; then
      rm -rf "${target}/skills/${legacy_skill_dir}"
      log "[cleanup] swept legacy skill subdir: ${target}/skills/${legacy_skill_dir}"
    fi
  done

  return 0
}

# ===== MAIN =====

echo ""
echo "Installing ${METHODOLOGY} v${EIDOLON_VERSION} → ${TARGET}"
echo "Hosts: ${HOSTS}"
echo ""

# --- step 1: create target directory ---
do_mkdir "${TARGET}"
do_mkdir "${TARGET}/skills"
do_mkdir "${TARGET}/templates"
do_mkdir "${TARGET}/templates/inbound"
do_mkdir "${TARGET}/schemas"
do_mkdir "${TARGET}/memories"

if [[ "$MANIFEST_ONLY" != "true" ]]; then

  # --- step 1b: sweep legacy v1.2-era artefacts (before any content write) ---
  cleanup_legacy_v1_2 "${TARGET}"

  # --- step 2: copy methodology files ---
  echo "Copying methodology files..."
  do_cp "${SCRIPT_DIR}/agent.md"  "${TARGET}/agent.md"
  do_cp "${SCRIPT_DIR}/SPEC.md"   "${TARGET}/SPEC.md"
  do_cp_r "${SCRIPT_DIR}/templates" "${TARGET}/templates"

  # --- ECL v1.0: copy ECL_VERSION marker ---
  do_cp "${SCRIPT_DIR}/ECL_VERSION" "${TARGET}/ECL_VERSION"

  # --- ECL v1.0: copy vendored schemas ---
  do_cp "${SCRIPT_DIR}/schemas/install.manifest.v1.json"                "${TARGET}/schemas/install.manifest.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/ecl-envelope.v1.json"                    "${TARGET}/schemas/ecl-envelope.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/_base-profile.v1.json"                   "${TARGET}/schemas/_base-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/apivr-completion-report-profile.v1.json" "${TARGET}/schemas/apivr-completion-report-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/repair-failed-report-profile.v1.json"    "${TARGET}/schemas/repair-failed-report-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/scout-report-profile.v1.json"            "${TARGET}/schemas/scout-report-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/spec-profile.v1.json"                    "${TARGET}/schemas/spec-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/root-cause-report-profile.v1.json"       "${TARGET}/schemas/root-cause-report-profile.v1.json"
  do_cp "${SCRIPT_DIR}/schemas/reasoning-report-profile.v1.json"        "${TARGET}/schemas/reasoning-report-profile.v1.json"

  # --- step 3: host dispatch files ---
  echo ""
  echo "Wiring hosts..."

  hosts_wired=()
  IFS=',' read -ra host_list <<< "$HOSTS"

  # Shared composable block — emitted identically to AGENTS.md, CLAUDE.md,
  # .github/copilot-instructions.md. Each Eidolon owns its marker-bounded
  # section within these files.
  SHARED_BLOCK="## APIVR-Δ — Brownfield feature implementation (v${EIDOLON_VERSION})

Entry:     \`${TARGET_REL}/agent.md\`
Full spec: \`${TARGET_REL}/SPEC.md\`
Cycle:     A (Analyze) → P (Plan) → I (Implement) → V (Verify) → Δ (Delta) / R (Reflect)

**P0 (non-negotiable):** Internal First (USE → EXTEND → WRAP → CREATE); test-anchored (expected test cases before implementation); boundary-respect (no out-of-scope edits); evidence-based (no speculation); escalate early (3 failures at same category = STOP)."

  # --- wire_skill: dual-write a skill file (EIIS v1.3 §4.2.4 / spec §3.0) ---
  #
  # wire_skill <skill_name>
  #
  # Dual-writes a skill file:
  #   - source-of-truth: ${TARGET}/skills/<skill_name>.md
  #   - vendor copy:     .claude/skills/${EIDOLON_SLUG}-<skill_name>/SKILL.md
  #
  # Source file resolved as: ${SCRIPT_DIR}/skills/<skill_name>.md
  #
  # Records both files in the manifest with role "skill" and matching SHA-256.
  # Bash 3.2 compatible (no associative arrays, no ${var,,}, no readarray).
  wire_skill() {
    local skill="$1"
    local src="${SCRIPT_DIR}/skills/${skill}.md"
    local dst_src="${TARGET}/skills/${skill}.md"
    local dst_vendor=".claude/skills/${EIDOLON_SLUG}-${skill}/SKILL.md"

    if [[ ! -f "${src}" ]]; then
      die "skill source not found: ${src}"
    fi

    mkdir -p "$(dirname "${dst_src}")"

    if [[ "$DRY_RUN" == "true" ]]; then
      act "[dry-run] cp ${src} → ${dst_src}"
    else
      cp "${src}" "${dst_src}"
      act "${dst_src}"
    fi

    if printf '%s\n' "${HOSTS}" | grep -q 'claude-code'; then
      mkdir -p "$(dirname "${dst_vendor}")"
      if [[ "$DRY_RUN" == "true" ]]; then
        act "[dry-run] cp ${src} → ${dst_vendor}"
      else
        cp "${src}" "${dst_vendor}"
        act "${dst_vendor}"
      fi
    fi
  }

  # Emit per-skill files for all 5 skills (flat layout, EIIS v1.3 §4.2.4.3).
  wire_skill "context-engineering"
  wire_skill "failure-recovery"
  wire_skill "memory-management"
  wire_skill "methodology"
  wire_skill "verify-incoming"

  # AGENTS.md — opt-in shared dispatch only.
  [[ "$SHARED_DISPATCH" == "true" ]] && upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK"

  for host in "${host_list[@]}"; do
    case "$host" in

      claude-code)
        hosts_wired+=("claude-code")
        [[ "$SHARED_DISPATCH" == "true" ]] && upsert_eidolon_block "CLAUDE.md" "$SHARED_BLOCK"

        # Subagent dispatch — always written when claude-code is wired.
        if [[ "$DRY_RUN" == "true" ]]; then
          act "[dry-run] write .claude/agents/${EIDOLON_NAME}.md"
        else
          mkdir -p ".claude/agents"
          if [[ ! -f ".claude/agents/${EIDOLON_NAME}.md" || "$FORCE" == "true" ]]; then
            cat > ".claude/agents/${EIDOLON_NAME}.md" <<AGENT
---
name: ${EIDOLON_NAME}
description: "Brownfield feature implementation — pattern-first, test-anchored, bounded failure recovery."
when_to_use: "After a SPECTRA spec exists (or an equivalent human-authored brief) and you need to implement a feature in an existing codebase with an established convention set."
tools: Read, Edit, Write, Grep, Glob, Bash(git:*), Bash(rspec:*), Bash(jest:*), Bash(pytest:*), Bash(go test:*)
methodology: ${METHODOLOGY}
methodology_version: "${EIDOLON_VERSION%.*}"
role: Coder — bounded implementer with test/pattern anchoring
handoffs: [idg]
---

APIVR-Δ runs the A→P→I→V→Δ/R cycle. Given a spec, it anchors on existing
patterns, implements in bounded chunks, verifies via the project's test
suite, and emits a delta/reflection when it completes or hits a bounded
failure.

See \`${TARGET}/agent.md\` for the P0 rules and
\`${TARGET}/SPEC.md\` for the full specification. Skills load on
demand — see \`${TARGET}/skills/\`.
AGENT
            act ".claude/agents/${EIDOLON_NAME}.md"
          else
            skip ".claude/agents/${EIDOLON_NAME}.md already exists (use --force to overwrite)"
          fi
        fi
        ;;

      copilot)
        hosts_wired+=("copilot")
        [[ "$SHARED_DISPATCH" == "true" ]] && \
          upsert_eidolon_block ".github/copilot-instructions.md" "$SHARED_BLOCK"
        ;;

      cursor)
        hosts_wired+=("cursor")
        # Per-skill .cursor/rules/apivr-<skill>.mdc already emitted by wire_skill.
        # Drop the legacy methodology-level apivr.mdc on --force.
        if [[ -d "./.cursor" ]]; then
          [[ -f "./.cursor/rules/${EIDOLON_NAME}.mdc" && "$FORCE" == "true" ]] && \
            rm -f "./.cursor/rules/${EIDOLON_NAME}.mdc"
        elif [[ -f "./.cursorrules" && "$SHARED_DISPATCH" == "true" ]]; then
          upsert_eidolon_block ".cursorrules" "$SHARED_BLOCK"
        elif [[ ! -d "./.cursor" && ! -f "./.cursorrules" ]]; then
          warn "cursor host requested but neither .cursor/ nor .cursorrules found — skipping"
          hosts_wired=("${hosts_wired[@]/cursor}")
        fi
        ;;

      opencode)
        hosts_wired+=("opencode")
        if [[ -d "./.opencode" ]]; then
          do_mkdir "./.opencode/agents"
          OPENCODE_FILE="./.opencode/agents/${EIDOLON_NAME}.md"
          if [[ -f "$OPENCODE_FILE" && "$FORCE" != "true" ]]; then
            skip "${OPENCODE_FILE} exists (pass --force to overwrite)"
          else
            do_write "$OPENCODE_FILE" "---
name: ${EIDOLON_NAME}
description: APIVR-Δ feature implementation methodology for brownfield codebases
---

You are the APIVR-Δ feature implementation agent.

Load your full instructions from: ${TARGET_REL}/agent.md
Full methodology: ${TARGET_REL}/SPEC.md

Cycle: A → P → I → V → Δ/R
"
          fi
        else
          warn "opencode host requested but .opencode/ not found — skipping"
          hosts_wired=("${hosts_wired[@]/opencode}")
        fi
        ;;

      codex)
        # EIIS v1.1 §4.5 — Codex subagent contract.
        # Two artefacts are written when codex is wired:
        #   1. Marker-bounded block in root AGENTS.md (§4.1.0; co-owned with
        #      copilot). This is written regardless of --shared-dispatch
        #      because AGENTS.md is Codex's primary instruction surface.
        #   2. Per-Eidolon subagent file at .codex/agents/<name>.md
        #      (§4.5.1). Filename is the namespace.
        # Cite: https://developers.openai.com/codex/guides/agents-md
        # Cite: https://developers.openai.com/codex/subagents
        hosts_wired+=("codex")
        upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK"

        if [[ "$DRY_RUN" == "true" ]]; then
          act "[dry-run] write .codex/agents/${EIDOLON_NAME}.md"
        else
          mkdir -p ".codex/agents"
          if [[ ! -f ".codex/agents/${EIDOLON_NAME}.md" || "$FORCE" == "true" ]]; then
            cat > ".codex/agents/${EIDOLON_NAME}.md" <<CODEX_AGENT
---
name: ${EIDOLON_NAME}
description: Brownfield feature implementation subagent — pattern-first, test-anchored, bounded failure recovery (APIVR-Δ A→P→I→V→Δ/R).
---

# APIVR-Δ — Codex subagent

APIVR-Δ runs the A→P→I→V→Δ/R cycle. Given a spec, it anchors on existing
patterns, implements in bounded chunks, verifies via the project's test
suite, and emits a delta/reflection when it completes or hits a bounded
failure.

Canonical methodology entry point: \`${TARGET_REL}/agent.md\`.
Full specification: \`${TARGET_REL}/SPEC.md\`.
Skills load on demand — see \`${TARGET_REL}/skills/\`.
CODEX_AGENT
            act ".codex/agents/${EIDOLON_NAME}.md"
          else
            skip ".codex/agents/${EIDOLON_NAME}.md already exists (use --force to overwrite)"
          fi
        fi
        ;;

      none)
        log "No hosts detected or specified. Skipping dispatch wiring."
        ;;

      *)
        warn "Unknown host: ${host} — skipping"
        ;;
    esac
  done

fi  # end MANIFEST_ONLY guard

# --- step 4: write manifest ---
echo ""
echo "Writing install manifest..."

INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

hosts_wired_json=""
if [[ ${#hosts_wired[@]} -gt 0 ]]; then
  for h in "${hosts_wired[@]}"; do
    [[ -n "$h" ]] && hosts_wired_json+="\"${h}\","
  done
  hosts_wired_json="[${hosts_wired_json%,}]"
else
  hosts_wired_json="[]"
fi

# Build files_written array and skills[] array (only if not dry-run)
files_written_json="[]"
skills_json="[]"
if [[ "$DRY_RUN" != "true" && -d "$TARGET" ]]; then
  fw=""
  add_fw() {
    local path="$1" role="$2" mode="$3"
    local sha
    sha="$(sha256_file "${TARGET}/${path}" 2>/dev/null || echo "00000000")"
    fw+="{ \"path\": \"${path}\", \"sha256\": \"${sha}\", \"role\": \"${role}\", \"mode\": \"${mode}\" },"
  }
  # add_fw_cwd <cwd-relative-path> <role> <mode> — record a file written at
  # the consumer cwd root (e.g. AGENTS.md, .codex/agents/<name>.md) rather
  # than under TARGET.
  add_fw_cwd() {
    local path="$1" role="$2" mode="$3"
    [[ -f "$path" ]] || return 0
    local sha
    sha="$(sha256_file "$path" 2>/dev/null || echo "00000000")"
    fw+="{ \"path\": \"${path}\", \"sha256\": \"${sha}\", \"role\": \"${role}\", \"mode\": \"${mode}\" },"
  }
  add_fw "agent.md"                        "entry-point" "created"
  add_fw "SPEC.md"                         "spec"        "created"
  add_fw "skills/context-engineering.md"   "skill"       "created"
  add_fw "skills/failure-recovery.md"      "skill"       "created"
  add_fw "skills/memory-management.md"     "skill"       "created"
  add_fw "skills/methodology.md"           "skill"       "created"
  add_fw "skills/verify-incoming.md"       "skill"       "created"

  # Build skills[] EIIS v1.3 §4.2.4 dual-write records.
  sk=""
  add_skill() {
    local name="$1"
    # source_path must match ^\\.eidolons/<slug>/skills/<skill>.md (EIIS v1.3 §4.2.4).
    # TARGET_REL strips the leading "./" so it is already ".eidolons/apivr".
    local src_path="${TARGET_REL}/skills/${name}.md"
    local vendor_path=".claude/skills/${EIDOLON_SLUG}-${name}/SKILL.md"
    local src_sha vendor_sha
    src_sha="$(sha256_file "${TARGET}/skills/${name}.md" 2>/dev/null || echo "00000000")"
    if printf '%s\n' "${HOSTS}" | grep -q 'claude-code' && [[ -f "${vendor_path}" ]]; then
      vendor_sha="$(sha256_file "${vendor_path}" 2>/dev/null || echo "00000000")"
      sk+="{ \"name\": \"${name}\", \"source_path\": \"${src_path}\", \"source_sha256\": \"${src_sha}\", \"vendor_path\": \"${vendor_path}\", \"vendor_sha256\": \"${vendor_sha}\" },"
    else
      sk+="{ \"name\": \"${name}\", \"source_path\": \"${src_path}\", \"source_sha256\": \"${src_sha}\" },"
    fi
  }
  add_skill "context-engineering"
  add_skill "failure-recovery"
  add_skill "memory-management"
  add_skill "methodology"
  add_skill "verify-incoming"
  skills_json="[${sk%,}]"
  add_fw "templates/discovery-report.md" "template"   "created"
  add_fw "templates/execution-plan.md"  "template"    "created"
  add_fw "templates/reflect-entry.md"   "template"    "created"
  # ECL v1.0 artefacts
  add_fw "ECL_VERSION"                                        "other"    "created"
  add_fw "schemas/ecl-envelope.v1.json"                      "other"    "created"
  add_fw "schemas/_base-profile.v1.json"                     "other"    "created"
  add_fw "schemas/apivr-completion-report-profile.v1.json"   "other"    "created"
  add_fw "schemas/repair-failed-report-profile.v1.json"      "other"    "created"
  add_fw "schemas/scout-report-profile.v1.json"              "other"    "created"
  add_fw "schemas/spec-profile.v1.json"                      "other"    "created"
  add_fw "schemas/root-cause-report-profile.v1.json"         "other"    "created"
  add_fw "schemas/reasoning-report-profile.v1.json"          "other"    "created"
  add_fw "templates/apivr-completion-report.envelope.json"   "template" "created"
  add_fw "templates/repair-failed-report.envelope.json"      "template" "created"
  add_fw "templates/reasoning-request.envelope.json"         "template" "created"
  add_fw "templates/inbound/scout-report.envelope.fixture.json"      "template" "created"
  add_fw "templates/inbound/spec.envelope.fixture.json"              "template" "created"
  add_fw "templates/inbound/root-cause-report.envelope.fixture.json" "template" "created"
  add_fw "templates/inbound/reasoning-report.envelope.fixture.json"  "template" "created"

  # EIIS v1.1 §4.5.5.1 — Codex dispatch artefacts when codex is wired.
  if [[ ${#hosts_wired[@]} -gt 0 ]]; then
    for _h in "${hosts_wired[@]}"; do
      if [[ "$_h" == "codex" ]]; then
        add_fw_cwd "AGENTS.md"                       "dispatch" "rewritten"
        add_fw_cwd ".codex/agents/${EIDOLON_NAME}.md" "dispatch" "created"
        break
      fi
    done
  fi

  files_written_json="[${fw%,}]"
fi

MANIFEST_CONTENT="{
  \"eidolon\": \"${EIDOLON_NAME}\",
  \"version\": \"${EIDOLON_VERSION}\",
  \"methodology\": \"${METHODOLOGY}\",
  \"installed_at\": \"${INSTALLED_AT}\",
  \"target\": \"${TARGET}\",
  \"spec_file\": \"${TARGET_REL}/SPEC.md\",
  \"skills\": ${skills_json},
  \"hosts_wired\": ${hosts_wired_json},
  \"files_written\": ${files_written_json},
  \"handoffs_declared\": {
    \"upstream\": [],
    \"downstream\": [\"idg\"]
  },
  \"token_budget\": {
    \"entry\": 0,
    \"working_set_target\": 1000
  },
  \"comm\": {
    \"envelope_version\": \"${ECL_VERSION_VAL}\",
    \"emits\": [\"apivr-completion-report\", \"repair-failed-report\", \"reasoning-request\"],
    \"verifies_incoming\": [\"scout-report\", \"spec\", \"root-cause-report\", \"reasoning-report\"]
  },
  \"security\": {
    \"reads_repo\": true,
    \"reads_network\": false,
    \"writes_repo\": true,
    \"persists\": [\"${TARGET_REL}/memories/\"]
  }
}"

if [[ "$DRY_RUN" == "true" ]]; then
  act "[dry-run] write ${MANIFEST_PATH}"
else
  printf '%s\n' "$MANIFEST_CONTENT" > "${MANIFEST_PATH}"
  act "${MANIFEST_PATH}"

  # patch token_budget.entry with actual measurement
  AGENT_TOKENS=$(wc -w < "${TARGET}/agent.md" | awk '{printf "%d", $1/0.75}')
  # rewrite manifest with real token count
  MANIFEST_CONTENT="${MANIFEST_CONTENT/\"entry\": 0/\"entry\": ${AGENT_TOKENS}}"
  printf '%s\n' "$MANIFEST_CONTENT" > "${MANIFEST_PATH}"
fi

# --- step 5: token measurement ---
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  AGENT_TOKENS=$(wc -w < "${SCRIPT_DIR}/agent.md" | awk '{printf "%d", $1/0.75}')
else
  AGENT_TOKENS=$(wc -w < "${TARGET}/agent.md" | awk '{printf "%d", $1/0.75}')
fi
echo "✓ agent.md: ${AGENT_TOKENS} tokens (budget: ≤1000)"

if [[ "$AGENT_TOKENS" -gt 1000 ]]; then
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    die "agent.md exceeds 1000-token budget (${AGENT_TOKENS} tokens). Aborting."
  else
    warn "agent.md token count ${AGENT_TOKENS} exceeds ≤1000 budget. Consider trimming."
  fi
fi

# --- step 6: smoke test banner ---
echo ""
echo "Installation complete. Smoke test:"
echo ""
echo "  Paste this prompt into your host to verify the agent is active:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────────┐"
echo "  │ You are the APIVR-Δ agent. A new feature request has arrived.       │"
echo "  │ State the complexity tier you would assign and the first step        │"
echo "  │ you would take.                                                      │"
echo "  └─────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  Expected: Agent names a complexity tier (Trivial/Standard/Complex/Uncertain),"
echo "  starts Analyze, mentions running a repo map before touching any file."
echo ""
echo "  Full eval missions: evals/canary-missions.md (in the Eidolon source repo)"
echo ""
