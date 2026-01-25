#!/usr/bin/env zs

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

############### Source helpers and environment variables from GenoMac-shared
# Helpers are sourced from the GenoMac-shared repo, which appears as a submodule
# NOTE:
# - The GMS_ prefix here indicates that these are helpers used by GenoMac-system, but the helpers
#   themselves are from GenoMac-shared, which appears as a submodule.
# - GenoMac-shared itself exports environment variables which give the locations of its subdirectories
#   relative to GenoMac-shared’s root. See, e.g., GENOMAC_SHARED_ROOT, GENOMAC_SHARED_RESOURCE_DIRECTORY,
#   GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY

GMS_HELPERS_DIR="${GMS_SCRIPTS:h}/external/genomac-shared/scripts"  # external/genomac-shared/scripts

# Source the master-helper script from GenoMac-shared submodule
source_with_report "${GMS_HELPERS_DIR}/helpers.sh"

############### Source environment variables specific to this repository
# Source repo-specific environment-variables script
source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

# Note: The above source of master_common_helpers_script will make available export_and_report(),
#       which is used directly below.
export_and_report GMS_HELPERS_DIR
