#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_subdermal_scriptS}/subdermis.sh"

function hypervisor() {
  # The outermost “dermal” layer of hypervisory supervison (the dermis). Ensures the 
  # GenoMac-system repository is updated before running the subdermal layer (subdermis). 
  #
  # It assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  #   - It is *not* necessary to update the clone before running this function, because this function
  #     updates the clone.
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  
  echo "Inside hypervisor"

  ############### Update clone
  # Updates the clone of GenoMac-system that is assumed to reside at GENOMAC_SYSTEM_LOCAL_DIRECTORY
  echo "Updating local clone of GenoMac-system at ${GENOMAC_SYSTEM_LOCAL_DIRECTORY}"
  update_genomac_system_repo

  # Run the subdermal layer of the hypervisor, which supervises the remainder of the process.
  subdermis

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
