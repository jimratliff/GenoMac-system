#!/usr/bin/env zsh

# Utility script for testing and interactively running spawn-related commands,
# anticipated to be used in conjunction with a justfile.

set -euo pipefail

this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
echo "Source ${initialization_script}"
source "${initialization_script}"

# Source required files
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn.sh"

function usage() {
  cat >&2 <<'EOF'
Usage:
  spawn-related-commands.sh test-user
  spawn-related-commands.sh ?????????
  spawn-related-commands.sh ?????????
EOF
}

function main() {
  emulate -L zsh
  set -euo pipefail

  if (( $# != 1 )); then
    usage
    return 64
  fi

  local command="$1"

  case "${command}" in
    test-user-exists)
      report_action_taken "Interactively (and iteratively) test for user existence"
      interactive_test_for_user_existence
      ;;

    what-is-startup-container)
      report_action_taken "Determine name of startup-volume container"
      determine_startup_container
      ;;

    ensure-volume-exists)
      report_action_taken "Interactively ensure volume exists"
      interactive_ensure_encrypted_apfs_volume_exists
      ;;

    test-home-directory-parent)
      report_action_taken "Interactively test path to parent of users’ home directories"
      interactive_ensure_encrypted_apfs_volume_exists
      ;;

    *)
      report_fail "Unknown system-states command: ${command}"
      usage
      return 64
      ;;
  esac
}

main "$@"
