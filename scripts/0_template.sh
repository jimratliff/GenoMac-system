#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

# Template for entry-point scripts

source "${HOME}/.genomac-system/scripts/0_initialize_me_first.sh

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
