#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

source "${HOME}/.genomac-system/scripts/0_initialize_me_first.sh

# Source required files
source "${GMS_HYPERVISOR_SCRIPTS}/alphahypervisor.sh"


function main() {
  alphahypervisor
}

main
