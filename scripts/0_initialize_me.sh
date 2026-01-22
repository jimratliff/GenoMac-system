#!/usr/bin/env zs

# Intended to be sourced at the beginning of every entry-point script in ~/.genomac-system/
#
# Performs:
# - Exports:
#   - GMS_SCRIPTS
#     - the path to ~/.genomac-system/scripts
#   - GMS_PREFS_SCRIPTS
#     - the path to ~/.genomac-system/scripts/prefs_scripts
#   - GMS_HELPERS_DIR
#     - the path to the helper scripts from the submodule GenoMac-shared
# - Sources:
#   - the helpers.sh script from GenoMac-shared, which in turn:
#     - sources all the other helpers-xxx.sh scripts from GenoMac-shared
#     - sources assign_common_environment_variables, which exports the environment variables 
#       that are common to both GenoMac-system and GenoMac-user
#   - assign_system_environment_variables.sh, which exports the environment variables that are 
#     specific to this repository
#
# It is assumed that the sourcing entry-point script is located at ~/.genomac-system/scripts
#
# Assumed directory structure
#   ~/.genomac-system/
#     external/
#       genomac-shared/
#         assign_common_environment_variables.sh
#         helpers-apps.h
#         …
#         helpers.sh
#     homebrew
#     resources
#       docs_to_display_to_user
#       images
#       sounds
#         alerts
#     scripts/
#       0_initialize_me.sh        # You are HERE!
#       an_entry_point_script.sh  # The script of interest, will source 0_initialize_me.sh
#       non-Homebrew_installation
#       prefs_scripts/
#       resource_installation
#     Makefile

set -euo pipefail

echo "Inside /scripts/0_initialize_me.sh"

# Resolve directory of the current script
this_script_path="${0:A}"
GMS_SCRIPTS="${this_script_path:h}"                                             # scripts




# Helpers are sourced from the GenoMac-shared repo, which appears as a submodule
GMS_HELPERS_DIR="${GMS_SCRIPTS:h}/external/genomac-shared/scripts"              # external/genomac-shared/scripts


GMS_RESOURCE_INSTALLATION_SCRIPTS="${GMS_SCRIPTS}/installations/of_resources"    # scripts/resource_installation

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
    return "Failed to source: $file"
    return 1
  fi
}

# Source master helpers script from GenoMac-shared submodule
source_with_report "${GMS_HELPERS_DIR}/helpers.sh"

# Source repo-specific environment-variables script
source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

# Source environment variables corresponding to enums for states
source_with_report "${GMS_SCRIPTS}/assign_enum_env_vars_for_states.sh"

# Note: The above source of master_common_helpers_script will make available export_and_report(),
#       which is used directly below.
export_and_report GMS_SCRIPTS

export_and_report GMS_HELPERS_DIR
export_and_report GMS_RESOURCE_INSTALLATION_SCRIPTS

echo "Leaving /scripts/0_initialize_me.sh"
