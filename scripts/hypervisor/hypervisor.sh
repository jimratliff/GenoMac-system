#!/usr/bin/env zsh

set -euo pipefail

function hypervisor() {
  # The outermost layer of hypervisory supervison. Ensures the GenoMac-system repository is updated
  # before running the subdermal layer (subdermis). 
  #
  # This is the function called first, directly, and immediately by `make run-hypervisor`.
  #
  # It assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  #   - It is *not* necessary to update the clone before running this function, because this function
  #     updates the clone.
  # - scripts/0_initialize_me_first.sh has been sourced
  
  echo "Inside hypervisor"

  ############### Update clone
  # Updates the clone of GenoMac-system that is assumed to reside at GENOMAC_SYSTEM_LOCAL_DIRECTORY
  echo "Updating local clone of GenoMac-system at ${GENOMAC_SYSTEM_LOCAL_DIRECTORY}"
  update_genomac_system_repo

  ############### Finish initializations
  # Now that repo is updated, we can finish the initialization process

  secondary_initialization_script="${GMS_SCRIPTS}/0_initialize_me_second.sh"
  source_with_report "${secondary_initialization_script}"

  ############### Spawn Hypervisor
  # Spawn the hypervisor that manages the bootstrapping/maintenance of the system-scoped configuration
  
  subdermal_script="${GMS_subdermal_scriptS}/subdermis.sh"
  source_with_report "$subdermal_script"

  # Run the subdermal layer of the hypervisor, which supervises the remainder of the process.
  # subdermis

  echo "Leaving hypervisor"
}

function update_genomac_system_repo() {
  # NOTE: The immediately below check for the existence of this repo is comically useless:
  #       if the repo has not been cloned, this script itself would not exist.
  if [[ ! -d ${GENOMAC_SYSTEM_LOCAL_DIRECTORY} || -z "$(ls -A ${GENOMAC_SYSTEM_LOCAL_DIRECTORY} 2>/dev/null)" ]]; then
    echo "You must clone the GenoMac-system repo to ${GENOMAC_SYSTEM_LOCAL_DIRECTORY} before running the Hypervisor"
    return 1
  fi
  
  cd "${GENOMAC_SYSTEM_LOCAL_DIRECTORY}"
  git pull --recurse-submodules origin main
}
