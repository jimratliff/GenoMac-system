#!/usr/bin/env zs

# The earliest component of initialization, designed to minimize the amount of repository 
# code on which it relies, while still supporting updating the repository.
# This allows this script to be called to support updating the repository, while minimizing the
# likelihood/severity of this small amount of relied-upon repository code being changed
# underneath when the repository is updated.
#
# Exports:
# - Environment variables
#   - GMS_LOCAL_DIRECTORY      ~/.genomac-system
#   - GMS_SCRIPTS              ${GMS_LOCAL_DIRECTORY}/scripts
#   - GMS_HYPERVISOR_SCRIPTS   ${GMS_SCRIPTS}/hypervisor
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
GMS_LOCAL_DIRECTORY="$HOME/.genomac-system"
GMS_SCRIPTS="${GMS_LOCAL_DIRECTORY}/scripts"
GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"

export_and_report "GMS_LOCAL_DIRECTORY"
export_and_report "GMS_SCRIPTS"
export_and_report "GMS_HYPERVISOR_SCRIPTS"
