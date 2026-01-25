#!/usr/bin/env zs

# Initializes any entry-point script by sourcing (a) helpers and cross-repo environment variables
# from GenoMac-shared and (b) environment variables specific to the GenoMac-system repository.
#
#
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

# Resolve directory of the current script
this_script_path="${0:A}"                       # ~/.genomac-system/scripts/0_initialize_me_first.sh
GENOMAC_SYSTEM_SCRIPTS="${this_script_path:h}"  # ~/.genomac-system/scripts
GENOMAC_SYSTEM_ROOT="${GMS_SCRIPTS:h}"          # ~/.genomac-system
GENOMAC_SHARED_ROOT_RELATIVE_TO_GENOMAC_SYSTEM="${GENOMAC_SYSTEM_ROOT}/external/genomac-shared"

############### Source helpers and environment variables from GenoMac-shared,
#               which appears as a submodule of GenoMac-system
HELPERS_FROM_GENOMAC_SHARED="${GENOMAC_SYSTEM_SCRIPTS:h}/external/genomac-shared/scripts"  # external/genomac-shared/scripts
# Source the master-helper script from GenoMac-shared submodule
source_with_report "${HELPERS_FROM_GENOMAC_SHARED}/helpers.sh"

############### Source environment variables specific to this repository
# Source repo-specific environment-variables script
source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

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
# GMS_SCRIPTS="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/scripts"

# export_and_report "GMS_SCRIPTS"






