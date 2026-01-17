#!/usr/bin/env zs

# Intended to be sourced at the beginning of every entry-point script in ~/.genomac-system/
#
# Performs:
# - Exports:
#   - GMS_SCRIPTS_DIR
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
#     scripts/
#       0_initialize_me.sh        # You are HERE!
#       an_entry_point_script.sh  # The script of interest, will source 0_initialize_me.sh
#       prefs_scripts/

set -euo pipefail

echo "Inside /scripts/0_initialize_me.sh"

# Resolve directory of the current script
this_script_path="${0:A}"

GMS_SCRIPTS_DIR="${this_script_path:h}"                                         # scripts
GMS_PREFS_SCRIPTS="${GMS_SCRIPTS_DIR}/prefs_scripts"                            # scripts/prefs_scripts
GMS_NON_HOMEBREW_INSTALL_SCRIPTS="${GMS_SCRIPTS_DIR}/non-Homebrew_installation" # scripts/non-Homebrew_installation
GMS_HELPERS_DIR="${GMS_SCRIPTS_DIR:h}/external/genomac-shared/scripts"          # external/genomac-shared/scripts

master_common_helpers_script="${GMS_HELPERS_DIR}/helpers.sh"
repo_specific_environment_variables_script="${GMS_SCRIPTS_DIR}/assign_system_environment_variables.sh"
environment_variables_for_state_enums_script="${GMS_SCRIPTS_DIR}/assign_enum_env_vars_for_states.sh"

function source_with_report() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  #
  # Defining this function here solves a chicken-or-egg problem: We’d like to use the helper 
  # safe_source(), but it hasn’t been sourced yet. The current function is quite as full functional 
  # but will do for the initial sourcing of helpers.
  local file="$1"
  if source "$file"; then
    echo "Sourced: $file"
  else
    return "Failed to source: $file"
    return 1
  fi
}

source_with_report "${master_common_helpers_script}"
source_with_report "${repo_specific_environment_variables_script}"
source_with_report "${environment_variables_for_state_enums_script}"

# Note: The above source of master_common_helpers_script will make available export_and_report(),
#       which is used directly below.
export_and_report GMS_NON_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_SCRIPTS_DIR
export_and_report GMS_PREFS_SCRIPTS
export_and_report GMS_HELPERS_DIR

echo "Leaving /scripts/0_initialize_me.sh"
