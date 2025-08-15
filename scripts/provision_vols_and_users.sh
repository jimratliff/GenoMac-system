#!/usr/bin/env zsh
# File: provision_vols_and_users.sh
#
# Creates APFS volumes (except Volume1) and local user accounts per JSON config
# streamed on stdin (ideal with: op read 'op://…/notesPlain' | sudo ./provision_vols_and_users.sh --stdin-json)
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
#     {"name":"Alice","uid":501,"vocation":"simple_admin","avatar":"/path/to/Alice.png"},
#     {"name":"Bob","uid":502,"vocation":"work","avatar":"/path/to/Bob.jpg"}
#   ]
# }

# --------------------------- Strict mode & setup ------------------------------
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (incl. GENOMAC_HELPER_DIR)
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers (expects report_* and success_or_not, etc.)
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Print assigned paths for diagnostic purposes
printf "\n📂 Path diagnostics:\n"
printf "this_script_dir:       %s\n" "$this_script_dir"
printf "GENOMAC_HELPER_DIR:    %s\n\n" "$GENOMAC_HELPER_DIR"

# ------------------------------ CLI parsing ----------------------------------
DRY_RUN=0
READ_FROM_STDIN=0
CONFIG_JSON=""

if [[ "${1:-}" == "--stdin-json" ]]; then
  READ_FROM_STDIN=1
  shift
elif [[ "${1:-}" == "--file" ]]; then
  # testing convenience: ./script --file /path/to/config.json
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

# ------------------------------ Dependencies ---------------------------------
if ! command -v jq >/dev/null 2>&1; then
  echo "This script requires 'jq'." >&2
  exit 2
fi

# ----------------------------- Utility wrappers ------------------------------
log() { printf "%s\n" "$*" >&2; }
run() {
  if (( DRY_RUN )); then
    log "DRY: $*"
  else
    eval "$@"
  fi
}

# ------------------------------- Parse config --------------------------------
container="$(jq -r '.apfs_container' <<<"$CONFIG_JSON")"

typeset -a VOLUMES
typeset -a PASSES
VOLUMES=("${(@f)$(jq -r '.volumes_ordered[]' <<<"$CONFIG_JSON")}")
PASSES=("${(@f)$(jq -r '.passphrases_ordered[]' <<<"$CONFIG_JSON")}")

if (( ${#VOLUMES[@]} != ${#PASSES[@]} )); then
  echo "volumes_ordered and passphrases_ordered differ in length." >&2
  exit 2
fi

typeset -A VOL_PASS
for i in {1..${#VOLUMES[@]}}; do
  VOL_PASS["${VOLUMES[$i]}"]="${PASSES[$i]}"
done

typeset -A VOC_VOL
while IFS=$'\t' read -r k v; do
  VOC_VOL["$k"]="$v"
done < <(jq -r '.vocation_to_volume | to_entries[] | "\(.key)\t\(.value)"' <<<"$CONFIG_JSON")

typeset -a USERS_JSON
USERS_JSON=("${(@f)$(jq -c '.users[]' <<<"$CONFIG_JSON")}")

# ------------------------- Unit-testable functions ----------------------------

# create_encrypted_apfs_volume
# Args:
#   $1 = apfs_container (e.g., /dev/disk3s2)
#   $2 = volume_name    (e.g., Volume2)
#   $3 = passphrase     (plaintext; fed via stdin to diskutil)
# Behavior:
#   - If volume exists, no-op (idempotent)
#   - Otherwise, creates encrypted APFS volume with provided passphrase
create_encrypted_apfs_volume() {
  emulate -L zsh
  set -euo pipefail

  local apfs_container="$1"
  local vol_name="$2"
  local passphrase="$3"

  report_action_taken "Ensuring APFS volume '$vol_name' exists and is encrypted"

  if diskutil apfs list | grep -q "Name: ${vol_name} "; then
    report "  - '$vol_name' already exists; leaving as-is"
    return 0
  fi

  local cmd="printf %s \"\${passphrase}\" | diskutil apfs addVolume \"${apfs_container}\" APFS \"${vol_name}\" -passphrase"
  run "$cmd"; success_or_not
}

# create_local_user_account
# Args:
#   $1 = name        (long+short per your spec)
#   $2 = uid         (numeric)
#   $3 = vocation    (used to resolve target volume and passphrase)
#   $4 = avatar_path (optional but recommended)
# Globals used:
#   VOC_VOL[] map, VOL_PASS[] map
# Behavior (pristine init):
#   - Hard-fail if shortname exists
#   - Hard-fail if UID exists
#   - Create account with home on /Volumes/<Vol>/Users/<Name>
#   - Set password via stdin (kept off argv)
#   - Set avatar if file exists
create_local_user_account() {
  emulate -L zsh
  set -euo pipefail

  local name="$1"
  local uid="$2"
  local vocation="$3"
  local avatar="$4"

  local vol="${VOC_VOL[$vocation]:-}"
  [[ -n "$vol" ]] || { report "ERROR: vocation '$vocation' has no mapped volume"; exit 1; }

  local pass="${VOL_PASS[$vol]:-}"
  [[ -n "$pass" ]] || { report "ERROR: volume '$vol' has no passphrase provided"; exit 1; }

  local shortname="$name"   # per your spec
  local home="/Volumes/${vol}/Users/${name}"

  # ---- Strict guards for pristine setups ----
  if id -u "$shortname" >/dev/null 2>&1; then
    report "ERROR: user '$shortname' already exists; refusing to modify on pristine init"
    exit 1
  fi

  # UID collision check
  if dscacheutil -q user | awk -v target="$uid" '$1=="uid:" && $2==target {found=1} END{exit(found?0:1)}'; then
    report "ERROR: UID '$uid' is already in use; refusing to proceed"
    exit 1
  fi
  # -------------------------------------------

  report_action_taken "Creating user '$name' (uid=$uid, vocation=$vocation, volume=$vol)"

  run "mkdir -p '$home'"; success_or_not

  # Create user with UID & home; password via stdin (kept off argv)
  local add_cmd="printf %s \"\${pass}\" | sysadminctl -addUser \"$shortname\" \
    -fullName \"$name\" -UID \"$uid\" -home \"$home\" -password -"
  run "$add_cmd"; success_or_not

  run "chown -R '$shortname':staff '$home'"; success_or_not

  if [[ -n "$avatar" && -f "$avatar" ]]; then
    run "dscl . -create /Users/'$shortname' Picture '$avatar'"; success_or_not
  else
    report "  - Avatar not found or not provided; skipping"
  fi
}

# ------------------------------ Script proper --------------------------------
report_start_phase 'Begin volume-and-user provisioning'

# Volumes:
# - Volume1 is the startup (FileVault) volume; we skip creating/encrypting it.
if (( ${#VOLUMES[@]} )); then
  report_action_taken "Creating encrypted APFS volumes (skipping Volume1 if present)"
  for idx in {2..${#VOLUMES[@]}}; do
    vol="${VOLUMES[$idx]}"
    pass="${PASSES[$idx]}"
    create_encrypted_apfs_volume "$container" "$vol" "$pass"
  done
fi

# Users:
report_action_taken "Creating local user accounts (hard-fail on conflicts)"
for uj in "${USERS_JSON[@]}"; do
  name="$(jq -r '.name' <<<"$uj")"
  uid="$(jq -r '.uid' <<<"$uj")"
  vocation="$(jq -r '.vocation' <<<"$uj")"
  avatar="$(jq -r '.avatar' <<<"$uj")"
  create_local_user_account "$name" "$uid" "$vocation" "$avatar"
done

report_end_phase 'Completed: volume-and-user provisioning'
