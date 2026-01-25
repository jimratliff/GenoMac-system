#!/usr/bin/env zsh

# Initializes any entry-point script by sourcing:
# - helpers and cross-repo environment variables from GenoMac-shared
# - environment variables specific to the GenoMac-system repository

# Fail early on unset variables or command failure
set -euo pipefail

local GENOMAC_SYSTEM_ROOT
local GENOMAC_SHARED_ROOT_RELATIVE_TO_GENOMAC_SYSTEM
local GENOMAC_SYSTEM_SCRIPTS
local this_script_path

this_script_path="${0:A}"                           # ~/.genomac-system/scripts/0_initialize_me_first.sh
GENOMAC_SYSTEM_SCRIPTS="${this_script_path:h}"      # ~/.genomac-system/scripts
GENOMAC_SYSTEM_ROOT="${GENOMAC_SYSTEM_SCRIPTS:h}"   # ~/.genomac-system
GENOMAC_SHARED_ROOT_RELATIVE_TO_GENOMAC_SYSTEM="${GENOMAC_SYSTEM_ROOT}/external/genomac-shared"

# Source the master-helper script from GenoMac-shared submodule, which sources helpers and environment variables
# from GenoMac-shared
local HELPERS_FROM_GENOMAC_SHARED
local master_helper_script

HELPERS_FROM_GENOMAC_SHARED="${GENOMAC_SHARED_ROOT_RELATIVE_TO_GENOMAC_SYSTEM}/scripts"  # external/genomac-shared/scripts
master_helper_script="${HELPERS_FROM_GENOMAC_SHARED}/helpers.sh"

echo "Source ${master_helper_script}"
source "${master_helper_script}"

# Source repo-specific environment-variables script
local repo_specific_environment_variables
repo_specific_environment_variables="${GENOMAC_SYSTEM_SCRIPTS}/assign_system_environment_variables.sh"

echo "Source ${repo_specific_environment_variables}"
source "${repo_specific_environment_variables}"
