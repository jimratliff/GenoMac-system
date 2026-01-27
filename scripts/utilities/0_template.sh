#!/usr/bin/env zsh

# Template for a utility script

# Fail early on unset variables or command failure
set -euo pipefail

# Source (a) helpers and cross-repo environment variables from GenoMac-shared and
# (b) environment variables specific to the GenoMac-system repository
initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
echo "Source ${initial_initialization_script}"
source "${initial_initialization_script}"

# Source required files
# safe_source "${GMS_HYPERVISOR_SCRIPTS}/hypervisor.sh"

function main() {
# do something
}

main
