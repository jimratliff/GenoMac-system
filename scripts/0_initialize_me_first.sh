#!/usr/bin/env zs

# Initializes any entry-point script by sourcing (a) helpers and cross-repo environment variables
# from GenoMac-shared and (b) environment variables specific to the GenoMac-system repository.

# Fail early on unset variables or command failure
set -euo pipefail

function initial_initialization() {

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

  this_script_path="${0:A}"                       # ~/.genomac-system/scripts/0_initialize_me_first.sh
  GENOMAC_SYSTEM_SCRIPTS="${this_script_path:h}"  # ~/.genomac-system/scripts
  GENOMAC_SYSTEM_ROOT="${GMS_SCRIPTS:h}"          # ~/.genomac-system
  GENOMAC_SHARED_ROOT_RELATIVE_TO_GENOMAC_SYSTEM="${GENOMAC_SYSTEM_ROOT}/external/genomac-shared"
  
  # Source helpers and environment variables from GenoMac-shared, which appears as a submodule of GenoMac-system
  HELPERS_FROM_GENOMAC_SHARED="${GENOMAC_SYSTEM_SCRIPTS:h}/external/genomac-shared/scripts"  # external/genomac-shared/scripts
  # Source the master-helper script from GenoMac-shared submodule, which sources all other components
  # from GenoMac-shared
  source_with_report "${HELPERS_FROM_GENOMAC_SHARED}/helpers.sh"
  
  # Source repo-specific environment-variables script
  source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

}










