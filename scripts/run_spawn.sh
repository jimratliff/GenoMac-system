#!/usr/bin/env zsh

# Runs a script to create the set of users (with volumes, as necessary, for their home directories).

# Fail early on unset variables or command failure
set -euo pipefail

# Source (a) helpers and cross-repo environment variables from GenoMac-shared and
# (b) environment variables specific to the GenoMac-system repository
initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
echo "Source ${initial_initialization_script}"
source "${initial_initialization_script}"

# Source required files
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn.sh"

function main() {
  create_user_accounts_for_this_Mac
}

main
