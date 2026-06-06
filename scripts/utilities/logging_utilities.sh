#!/usr/bin/env zsh

# Utility script to open (a) the latest log file and (b) the directory containing the log files.

set -euo pipefail

this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
echo "Source ${initialization_script}"
source "${initialization_script}"

function usage() {
  local script_name="${0:t}"
  cat >&2 <<EOF
Usage:
  ${script_name} open-latest
  ${script_name} open-directory
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
    open-latest)
      report_action_taken "Show latest log file"
      open_latest_log_file ; success_or_not
      ;;

    open-directory)
      report_action_taken "Open log-file directory"
      open_logs_directory ; success_or_not
      ;;

    *)
      report_fail "Unknown logging command: ${command}"
      usage
      return 64
      ;;
  esac
}

main "$@"
