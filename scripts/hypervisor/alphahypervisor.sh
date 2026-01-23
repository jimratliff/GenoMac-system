#!/usr/bin/env zsh

set -euo pipefail

function alphahypervisor() {
  # Supervises the hypervisor by ensuring the GenoMac-system repository is updated before
  # running the hypervisor. 
  #
  # This is the function called first, directly, and immediately by `make run-hypervisor`.
  #
  # It assumes that GenoMac-system has been cloned locally to GMS_LOCAL_DIRECTORY (~/.genomac-system).
  # It is *not* necessary to update the clone before running this function, because this function updates the clone.
  

  echo "Inside alphahypervisor"

  ############### Bootstrapping: Source initial initialization script
  # This will make available:
  # - Environment variables
  #   - GMS_LOCAL_DIRECTORY      ~/.genomac-system
  #   - GMS_SCRIPTS              ${GMS_LOCAL_DIRECTORY}/scripts
  #   - GMS_HYPERVISOR_SCRIPTS   ${GMS_SCRIPTS}/hypervisor
  # - Functions
  #   - export_and_report
  #   - source_with_report
  #     - This will be disfavored relative to safe_source, once safe_source becomes available
  #       after helper-misc.sh is sourced

  # WARNING: The below path for initial_initialization_script is hard-wired (without reference
  # to the appropriate environment variable (GMS_LOCAL_DIRECTORY) and needs to be monitored for 
  # continued appropriateness.
  initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"
  if source "$initial_initialization_script" 2>/dev/null; then
    echo "Sourced: $initial_initialization_script"
  else
    echo "Failed to source: $initial_initialization_script"
    return 1
  fi

  ###

  ############### Update clone
  # Updates the clone of GenoMac-system that is assumed to reside at GMS_LOCAL_DIRECTORY
  echo "Updating local clone of GenoMac-system at ${GMS_LOCAL_DIRECTORY}"
  update_genomac_system_repo

  ############### Finish initializations
  # Now that repo is updated, we can finish the initialization process

  secondary_initialization_script="${GMS_HYPERVISOR_SCRIPTS}/0_initialize_me_second.sh"
  source_with_report "${secondary_initialization_script}"

  ############### Spawn Hypervisor
  # Spawn the hypervisor that manages the bootstrapping/maintenance of the system-scoped configuration
  
  hypervisor_script="${GMS_HYPERVISOR_SCRIPTS}/run_hypervisor.sh"
  source_with_report "$hypervisor_script"

  run_hypervisor

  echo "Leaving alphahypervisor"
}

function update_genomac_system_repo() {
  # NOTE: The immediately below check for the existence of this repo is comically useless:
  #       if the repo has not been cloned, this script itself would not exist.
  if [[ ! -d ${GMS_LOCAL_DIRECTORY} || -z "$(ls -A ${GMS_LOCAL_DIRECTORY} 2>/dev/null)" ]]; then
    echo "You must clone the GenoMac-system repo to ${GMS_LOCAL_DIRECTORY} before running the Hypervisor"
    return 1
  fi
  
  cd "${GMS_LOCAL_DIRECTORY}"
  git pull --recurse-submodules origin main
}
