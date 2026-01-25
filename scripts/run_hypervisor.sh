#!/usr/bin/env zs

# Runs the function alphahypervisor, which is the entry point for the Hypervisor process.

# Fail early on unset variables or command failure
set -euo pipefail

initial_initialization_script
initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"

if source "$initial_initialization_script" 2>/dev/null; then
  echo "Sourced: $initial_initialization_script"
else
  echo "Failed to source: $initial_initialization_script"
  return 1
fi

secondary_initialization_script="${GMS_SCRIPTS}/0_initialize_me_second.sh"
source_with_report "${secondary_initialization_script}"

# Source required files
source "${GMS_HYPERVISOR_SCRIPTS}/hypervisor.sh"


function main() {
  hypervisor
}

main
