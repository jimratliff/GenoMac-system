#!/usr/bin/env zsh
# File: provision_vols_and_users.sh
#
# Creates encrypted APFS volumes (idempotent: create if missing, skip if present)
# and local user accounts per JSON config streamed on stdin:
#
#   Typical usage with 1Password CLI:
#     op read 'op://<Vault>/<Item>/notesPlain' | sudo ./provision_vols_and_users.sh --stdin-json
#
# Notes on dependencies:
#   - This script expects the JSON on stdin; it does NOT call `op` itself.
#     If you’re piping from 1Password, you’ll need the 1Password CLI installed (`op`).
#     If you’re supplying JSON via --file or from another program, `op` is not required.
#
# JSON shape (example):
# {
#   "apfs_container": "/dev/disk3s2",
#   "volumes_ordered": ["Volume1","Volume2","Volume3","Volume4"],
#   "passphrases_ordered": ["<pass-1>","<pass-2>","<pass-3>","<pass-4>"],
#   "vocation_to_volume": {
#     "simple_admin":"Volume1","implementor":"Volume1","unsullied":"Volume1",
#     "productive":"Volume2","work":"Volume3","auxiliary":"Volume4"
#   },
#   "users": [
#     {"name":"Alice","uid":501,"vocation":"simple_admin","avatar":"Alice.png"},
#     {"name":"Bob","uid":502,"vocation":"work","avatar":"Bob.jpg"}
#   ]
# }
#
# Environment expected (via assign_environment_variables.sh):
#   - GENOMAC_HELPER_DIR
#   - GENOMAC_USER_LOGIN_PICTURES_DIRECTORY  (directory containing avatar images)

# --------------------------- Strict mode & setup ------------------------------
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (incl. GENOMAC_HELPER_DIR, GENOMAC_USER_LOGIN_PICTURES_DIRECTORY)
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers (expects report_* and success_or_not, etc.)
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# ----------------------------- Utility wrappers ------------------------------
function log() { printf "%s\n" "$*" >&2; }
function run() {
  if (( DRY_RUN )); then
    log "DRY: $*"
  else
    eval "$@"
  fi
}

# ------------------------- Unit-testable functions ----------------------------
function create_encrypted_apfs_volume() {
  emulate -L zsh
  set -euo pipefail

  local apfs_container="$1"
  local vol_name="$2"
  local passphrase="$3"

  report_action_taken "Ensuring encrypted APFS volume '$vol_name' exists"

  if diskutil apfs list | grep -q "Name: ${vol_name} "; then
    report "  - '$vol_name' already exists; skipping creation"
    return 0
  fi

  local cmd="printf %s \"\${passphrase}\" | diskutil apfs addVolume \"${apfs_container}\" APFS \"${vol_name}\" -passphrase"
  run "$cmd"; success_or_not
  report "  - Created encrypted APFS volume '$vol_name'"
}

function create_local_user_account() {
  emulate -L zsh
  set -euo pipefail

  local name="$1"
  local uid="$2"
  local vocation="$3"
  local avatar_rel="$4"

  local vol="${VOC_VOL[$vocation]:-}"
  [[ -n "$vol" ]] || { report "ERROR: vocation '$vocation' has no mapped volume"; exit 1; }

  local pass="${VOL_PASS[$vol]:-}"
  [[ -n "$pass" ]] || { report "ERROR: volume '$vol' has no passphrase provided"; exit 1; }

  local shortname="$name"
  local home="/Volumes/${vol}/Users/${name}"

  if id -u "$shortname" >/dev/null 2>&1; then
    report "ERROR: user '$shortname' already exists; refusing to modify on pristine init"
    exit 1
  fi

  if dscacheutil -q user | awk -v target="$uid" '$1=="uid:" && $2==target {found=1} END{exit(found?0:1)}'; then
    report "ERROR: UID '$uid' is already in use; refusing to proceed"
    exit 1
  fi

  report_action_taken "Creating user '$name' (uid=$uid, vocation=$vocation, volume=$vol)"

  run "mkdir -p '$home'"; success_or_not

  local add_cmd="printf %s \"\${pass}\" | sysadminctl -addUser \"$shortname\" \
    -fullName \"$name\" -UID \"$uid\" -home \"$home\" -password -"
  run "$add_cmd"; success_or_not

  run "chown -R '$shortname':staff '$home'"; success_or_not

  local avatar_abs=""
  if [[ -n "${avatar_rel}" ]]; then
    avatar_abs="${GENOMAC_USER_LOGIN_PICTURES_DIRECTORY%/}/${avatar_rel}"
    if [[ -f "$avatar_abs" ]]; then
      run "dscl . -create /Users/'$shortname' Picture '$avatar_abs'"; success_or_not
    else
      report "  - Avatar file not found at '$avatar_abs'; user will have the default picture"
    fi
  else
    report "  - No avatar filename provided; user will have the default picture"
  fi
}

# ------------------------------ Main wrapper ---------------------------------
function main() {
  printf "\n📂 Path diagnostics:\n"
  printf "this_script_dir:                       %s\n" "$this_script_dir"
  printf "GENOMAC_HELPER_DIR:                    %s\n" "$GENOMAC_HELPER_DIR"
  printf "GENOMAC_USER_LOGIN_PICTURES_DIRECTORY: %s\n\n" "${GENOMAC_USER_LOGIN_PICTURES_DIRECTORY:-<unset>}"

  DRY_RUN=0
  READ_FROM_STDIN=0
  CONFIG_JSON=""

  if [[ "${1:-}" == "--stdin-json" ]]; then
    READ_FROM_STDIN=1
    shift
  elif [[ "${1:-}" == "--file" ]]; then
    shift
    CONFIG_JSON="$(< "${1:?Provide path to JSON config file}")"
    shift
  fi

  if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
  fi

  if (( READ_FROM_STDIN )); then
    CONFIG_JSON="$(cat -)"
  fi

  if [[ -z "${CONFIG_JSON}" ]]; then
    echo "Usage:" >&2
    echo "  op read 'op://<Vault>/<Item>/notesPlain' | sudo $0 --stdin-json [--dry-run]" >&2
    echo "  sudo $0 --file /path/to/config.json [--dry-run]" >&2
    exit 2
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "This script requires 'jq'." >&2
    exit 2
  fi

  if (( READ_FROM_STDIN )) && ! command -v op >/dev/null 2>&1; then
    report "Note: 'op' (1Password CLI) not found in PATH. That's fine if you're piping JSON from elsewhere; if you intended to use 1Password CLI, install it first."
  fi

  container="$(jq -r '.apfs_container' <<<"$CONFIG_JSON")"
  typeset -a VOLUMES PASSES
  VOLUMES=("${(@f)$(jq -r '.volumes_ordered[]' <<<"$CONFIG_JSON")}")
  PASSES=("${(@f)$(jq -r '.passphrases_ordered[]' <<<"$CONFIG_JSON")}")

  if (( ${#VOLUMES[@]} != ${#PASSES[@]} )); then
    echo "volumes_ordered and passphrases_ordered differ in length." >&2
    exit 2
  fi

  typeset -A VOL_PASS VOC_VOL
  for i in {1..${#VOLUMES[@]}}; do
    VOL_PASS["${VOLUMES[$i]}"]="${PASSES[$i]}"
  done
  while IFS=$'\t' read -r k v; do
    VOC_VOL["$k"]="$v"
  done < <(jq -r '.vocation_to_volume | to_entries[] | "\(.key)\t\(.value)"' <<<"$CONFIG_JSON")

  typeset -a USERS_JSON
  USERS_JSON=("${(@f)$(jq -c '.users[]' <<<"$CONFIG_JSON")}")

  report_start_phase 'Begin volume-and-user provisioning'

  if (( ${#VOLUMES[@]} )); then
    report_action_taken "Ensuring declared encrypted APFS volumes exist"
    for idx in {1..${#VOLUMES[@]}}; do
      vol="${VOLUMES[$idx]}"
      pass="${PASSES[$idx]}"
      create_encrypted_apfs_volume "$container" "$vol" "$pass"
    done
  fi

  report_action_taken "Creating local user accounts (hard-fail on conflicts)"
  for uj in "${USERS_JSON[@]}"; do
    name="$(jq -r '.name' <<<"$uj")"
    uid="$(jq -r '.uid' <<<"$uj")"
    vocation="$(jq -r '.vocation' <<<"$uj")"
    avatar_rel="$(jq -r '.avatar' <<<"$uj")"
    create_local_user_account "$name" "$uid" "$vocation" "$avatar_rel"
  done

  report_end_phase 'Completed: volume-and-user provisioning'
}

# Only run main() if executed directly, not sourced (like Python’s if __name__ == "__main__")
if [[ "${(%):-%N}" == "$0" ]]; then
  main "$@"
fi
