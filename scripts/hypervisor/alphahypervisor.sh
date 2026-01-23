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

  # WARNING: This path is hard-wired and needs to be monitored for continued appropriateness
  initial_initialization_script="$HOME/.genomac-system/scripts/0_initialize_me_first.sh"

  if source "$initial_initialization_script" 2>/dev/null; then
    echo "Sourced: $initial_initialization_script"
  else
    echo "Failed to source: $initial_initialization_script"
    return 1
  fi

  ###

  # Updates the clone of GenoMac-system that is assumed to reside at GENOMAC_SYSTEM_LOCAL_DIRECTORY
  echo "Updating local clone of GenoMac-system"
  update_genomac_system_repo

  # Now that GenoMac-system has been updated, spawn the hypervisor that manages the bootstrapping/maintenance
  # of the system-scoped configuration



  initialization_script="$GMS_HYPERVISOR_SCRIPTS/0_initialize_me.sh"
  hypervisor_script="$GMS_HYPERVISOR_SCRIPTS/run_hypervisor.sh"
  source_with_report "$initialization_script"
  source_with_report "$hypervisor_script"

  run_hypervisor

  echo "Leaving alphahypervisor"

}

function update_genomac_system_repo() {
  if [[ ! -d ~/.genomac-system || -z "$(ls -A ~/.genomac-system 2>/dev/null)" ]]; then
    echo "You must clone the GenoMac-system repo to ${GMS_LOCAL_DIRECTORY} before running the Hypervisor"
    return 1
  fi
  
  cd "${GMS_LOCAL_DIRECTORY}"
  git pull --recurse-submodules origin main
}
