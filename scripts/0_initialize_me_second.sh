#!/usr/bin/env zs

# Sources (a) common (cross-repo) (1) helpers and (2) environment variables from GenoMac-shared
# and (b) environment variables specific to this repository.
#
# This file is intended to be sourced *after* the GenoMac-system repo is updated. Thus, unlike
# 0_initialize_me_first, this script is free to use the full extent of GenoMac-system and
# GenoMac-shared code without fear of having that code be changed in the background due to a 
# repo update.
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
# Performs:
# - Exports:
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

############### Source helpers and environment variables from GenoMac-shared
# Helpers are sourced from the GenoMac-shared repo, which appears as a submodule
# NOTE:
# - The GMS_ prefix here indicates that these are helpers used by GenoMac-system, but the helpers
#   themselves are from GenoMac-shared, which appears as a submodule.
# - GenoMac-shared itself exports environment variables which give the locations of its subdirectories
#   relative to GenoMac-shared’s root. See, e.g., GENOMAC_SHARED_ROOT, GENOMAC_SHARED_RESOURCE_DIRECTORY,
#   GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY

GMS_HELPERS_DIR="${GMS_SCRIPTS:h}/external/genomac-shared/scripts"  # external/genomac-shared/scripts

# Source master helpers script from GenoMac-shared submodule
source_with_report "${GMS_HELPERS_DIR}/helpers.sh"

############### Source environment variables specific to this repository
# Source repo-specific environment-variables script
source_with_report "${GMS_SCRIPTS}/assign_system_environment_variables.sh"

# Note: The above source of master_common_helpers_script will make available export_and_report(),
#       which is used directly below.
export_and_report GMS_HELPERS_DIR

echo "Leaving /scripts/0_initialize_me.sh"
