#!/usr/bin/env zsh

# Fail early on unset variables or command failure
set -euo pipefail

# Template for entry-point scripts

initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
if source "$initial_initialization_script" 2>/dev/null; then
  echo "Sourced: $initial_initialization_script"
else
  echo "Failed to source: $initial_initialization_script"
  return 1
fi

secondary_initialization_script="${GMS_SCRIPTS}/0_initialize_me_second.sh"
source_with_report "${secondary_initialization_script}"

############### SCRIPT PROPER BEGINS NOW

# Source required files
# safe_source "${GMS_HYPERVISOR_SCRIPTS}/alphahypervisor.sh"

function some_function() {
  report_start_phase_standard

  report "I am doing something important"

  report_end_phase_standard

}

function main() {
  some_function
}
