#!/usr/bin/env zs

# Sources common (cross-repo) helpers and environment variables from GenoMac-shared.
#
# This file is intended to be sourced *after* the GenoMac-system repo is updated. Thus, unlike
# 
#
# Assumes that scripts/0_initialize_me_first.sh has already been sourced, from which is received:
# - Environment variables
#   - GMS_LOCAL_DIRECTORY      ~/.genomac-system
#   - GMS_SCRIPTS              ${GMS_LOCAL_DIRECTORY}/scripts
#   - GMS_HYPERVISOR_SCRIPTS   ${GMS_SCRIPTS}/hypervisor
# - Functions
#   - export_and_report
#   - source_with_report
#     - This will be disfavored relative to safe_source, once safe_source becomes available
#       after helper-misc.sh is sourced
#

#
# Performs:
# - Exports:
#   - GMS_SCRIPTS
#     - the path to ~/.genomac-system/scripts
#   - GMS_SETTINGS_SCRIPTS
#     - the path to ~/.genomac-system/scripts/settings
#   - GMS_HELPERS_DIR
#     - the path to the helper scripts from the submodule GenoMac-shared
# - Sources:
#   - the helpers.sh script from GenoMac-shared, which in turn:
#     - sources all the other helpers-xxx.sh scripts from GenoMac-shared
#     - sources assign_common_environment_variables, which exports the environment variables 
#       that are common to both GenoMac-system and GenoMac-user
#   - assign_system_environment_variables.sh, which exports the environment variables that are 
#     specific to this repository


set -euo pipefail

echo "Inside /scripts/0_initialize_me_second.sh"

# Resolve directory of the current script
# this_script_path="${0:A}"
# GMS_SCRIPTS="${this_script_path:h}" # scripts

# Helpers are sourced from the GenoMac-shared repo, which appears as a submodule
GMS_HELPERS_DIR="${GMS_SCRIPTS:h}/external/genomac-shared/scripts"  # external/genomac-shared/scripts

# Source master helpers script from GenoMac-shared submodule
source_with_report "${GMS_HELPERS_DIR}/helpers.sh"

# Source repo-specific environment-variables script
source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

# Source environment variables corresponding to enums for states
source_with_report "${GMS_HYPERVISOR_SCRIPTS}/assign_enum_env_vars_for_states.sh"

# Note: The above source of master_common_helpers_script will make available export_and_report(),
#       which is used directly below.
# export_and_report GMS_SCRIPTS
export_and_report GMS_HELPERS_DIR

echo "Leaving /scripts/0_initialize_me.sh"
