#!/usr/bin/env zs

# Provides the bare minimum of configuration to support (a) updating the local clone of
# GenoMac-system and (b) launching the script that begins the post-updating remainder of
# the Hypervisor process.
#
# By minimizing the amount of repository code sourced prior to updating the repo, it minimizes
# the likelihood that any recent change in the remote repo’s code (between the pre-update state 
# of the local clone and the post-update state of the local clone) would implicate the current
# script.
#
# WARNING: If the current script file changes materially (e.g., other than comments), the 
#          Hypervisor should be aborted immediately after the clone is updated and the Hypervisor
#          should then be restarted.
#
# Exports:
# - Environment variables
#   - GENOMAC_SYSTEM_LOCAL_DIRECTORY   ~/.genomac-system
#   - GMS_SCRIPTS                      ${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/scripts
#   - GMS_HYPERVISOR_SCRIPTS           ${GMS_SCRIPTS}/hypervisor
# - Functions
#   - export_and_report
#   - source_with_report
#     - This will be disfavored relative to safe_source, once safe_source becomes available
#       after helper-misc.sh is sourced

# Fail early on unset variables or command failure
set -euo pipefail

function export_and_report() {
  local var_name="$1"
  echo "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

function source_with_report() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  #
  # Defining this function here solves a chicken-or-egg problem: We’d like to use the helper 
  # safe_source(), but it hasn’t been sourced yet. The current function is not quite as full functional 
  # but will do for the initial sourcing of helpers.
  local file="$1"
  if source "$file"; then
    echo "Sourced: $file"
  else
    echo "Failed to source: $file"
    return 1
  fi
}

# Specify local directory into which the GenoMac-system repository will be cloned
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"
GMS_SCRIPTS="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/scripts"
GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"

export_and_report "GENOMAC_SYSTEM_LOCAL_DIRECTORY"
export_and_report "GMS_SCRIPTS"
export_and_report "GMS_HYPERVISOR_SCRIPTS"
