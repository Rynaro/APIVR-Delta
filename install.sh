#!/usr/bin/env bash
set -euo pipefail

EIDOLON_NAME="apivr"
EIDOLON_VERSION="3.0.4"
METHODOLOGY="APIVR-Δ"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# ===== MAIN =====

echo ""
echo "Installing ${METHODOLOGY} v${EIDOLON_VERSION} → ${TARGET}"
echo "Hosts: ${HOSTS}"
echo ""

# --- step 1: create target directory ---
do_mkdir "${TARGET}"
do_mkdir "${TARGET}/skills"
do_mkdir "${TARGET}/templates"
do_mkdir "${TARGET}/memories"

if [[ "$MANIFEST_ONLY" != "true" ]]; then

  # --- step 2: copy methodology files ---
  echo "Copying methodology files..."
  do_cp "${SCRIPT_DIR}/agent.md"  "${TARGET}/agent.md"
  do_cp "${SCRIPT_DIR}/apivr.md"  "${TARGET}/apivr.md"
  do_cp_r "${SCRIPT_DIR}/skills"    "${TARGET}/skills"
  do_cp_r "${SCRIPT_DIR}/templates" "${TARGET}/templates"

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
Full spec: \`${TARGET_REL}/apivr.md\`
Cycle:     A (Analyze) → P (Plan) → I (Implement) → V (Verify) → Δ (Delta) / R (Reflect)

**P0 (non-negotiable):** Internal First (USE → EXTEND → WRAP → CREATE); test-anchored (expected test cases before implementation); boundary-respect (no out-of-scope edits); evidence-based (no speculation); escalate early (3 failures at same category = STOP)."

  # --- Per-skill vendor wiring helpers ---
  strip_frontmatter() {
    local f="$1"
    if [[ "$(head -1 "$f")" == "---" ]]; then
      awk 'NR==1 && /^---$/ {in_fm=1; next}
           in_fm && /^---$/ {in_fm=0; next}
           !in_fm {print}' "$f"
    else
      cat "$f"
    fi
  }
  extract_fm_field() {
    awk -v field="$2" '
      NR==1 && /^---$/ { in_fm=1; next }
      in_fm && /^---$/ { exit }
      in_fm { p=index($0, field ":"); if (p==1) { sub("^" field ":[[:space:]]*", ""); print; exit } }
    ' "$1"
  }
  wire_skill() {
    local src_dir="$1" skill_name="$2"
    local src_skill="${src_dir}/SKILL.md"
    [[ -f "$src_skill" ]] || return
    local description
    description="$(extract_fm_field "$src_skill" "description")"
    [[ -z "$description" ]] && description="${skill_name}"

    for h in "${host_list[@]}"; do
      case "$h" in
        claude-code)
          if [[ "$DRY_RUN" == "true" ]]; then
            act "[dry-run] copy ${src_dir}/ → .claude/skills/${skill_name}/"
          else
            rm -rf ".claude/skills/${skill_name}"
            mkdir -p ".claude/skills/${skill_name}"
            cp -R "${src_dir}/." ".claude/skills/${skill_name}/"
            act ".claude/skills/${skill_name}/"
          fi
          ;;
        copilot)
          if [[ "$DRY_RUN" == "true" ]]; then
            act "[dry-run] write .github/instructions/${skill_name}.instructions.md"
          else
            mkdir -p ".github/instructions"
            { echo "---"; echo "applyTo: \"**\""; echo "description: \"${description}\""; echo "---"; strip_frontmatter "$src_skill"; } > ".github/instructions/${skill_name}.instructions.md"
            act ".github/instructions/${skill_name}.instructions.md"
          fi
          ;;
        cursor)
          if [[ "$DRY_RUN" == "true" ]]; then
            act "[dry-run] write .cursor/rules/${skill_name}.mdc"
          else
            mkdir -p ".cursor/rules"
            { echo "---"; echo "description: \"${description}\""; echo "alwaysApply: false"; echo "---"; strip_frontmatter "$src_skill"; } > ".cursor/rules/${skill_name}.mdc"
            act ".cursor/rules/${skill_name}.mdc"
          fi
          ;;
      esac
    done
  }

  # Emit per-skill vendor files for every skill directory under skills/.
  for skill_dir in "${SCRIPT_DIR}"/skills/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    wire_skill "$skill_dir" "${EIDOLON_NAME}-${skill_name}"
  done

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
\`${TARGET}/apivr.md\` for the full specification. Skills load on
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
Full methodology: ${TARGET_REL}/apivr.md

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
Full specification: \`${TARGET_REL}/apivr.md\`.
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

# Build files_written array (only if not dry-run)
files_written_json="[]"
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
  add_fw "agent.md"                     "entry-point" "created"
  add_fw "apivr.md"                     "spec"        "created"
  add_fw "skills/apivr-methodology.md"  "skill"       "created"
  add_fw "skills/context-engineering.md" "skill"      "created"
  add_fw "skills/failure-recovery.md"   "skill"       "created"
  add_fw "skills/memory-management.md"  "skill"       "created"
  add_fw "templates/discovery-report.md" "template"   "created"
  add_fw "templates/execution-plan.md"  "template"    "created"
  add_fw "templates/reflect-entry.md"   "template"    "created"

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
  \"hosts_wired\": ${hosts_wired_json},
  \"files_written\": ${files_written_json},
  \"handoffs_declared\": {
    \"upstream\": [],
    \"downstream\": []
  },
  \"token_budget\": {
    \"entry\": 0,
    \"working_set_target\": 1000
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
