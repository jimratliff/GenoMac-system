#!/usr/bin/env zsh

# Utility script to perform maintenance and informational actions on the set of system states

set -euo pipefail

this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
echo "Source ${initialization_script}"
source "${initialization_script}"

function usage() {
  cat >&2 <<'EOF'
Usage:
  system_states.zsh show
  system_states.zsh clear-session
  system_states.zsh clear-all
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
    show)
      report_action_taken "Open system local state directory"
      open "${GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY}" ; success_or_not
      ;;

    clear-session)
      report_action_taken "Clear system SESH states"
      delete_all_system_SESH_states ; success_or_not
      ;;

    clear-all)
      report_action_taken "Clear all system states"
      delete_all_system_states ; success_or_not
      ;;

    *)
      report_fail "Unknown system-states command: ${command}"
      usage
      return 64
      ;;
  esac
}

main "$@"
