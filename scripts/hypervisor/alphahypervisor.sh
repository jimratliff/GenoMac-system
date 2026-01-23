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
  #
  # Side effects:
  # - Exports
  #   - GMS_LOCAL_DIRECTORY="$HOME/.genomac-system"
  #   - GMS_SCRIPTS="${GMS_LOCAL_DIRECTORY}/scripts"
  #   - GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"

  echo "Inside alphahypervisor"

  # Specify local directory into which the GenoMac-system repository will be cloned
  GMS_LOCAL_DIRECTORY="$HOME/.genomac-system"
  GMS_SCRIPTS="${GMS_LOCAL_DIRECTORY}/scripts"
  GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"
  
  function export_and_report() {
    local var_name="$1"
    echo "export $var_name: '${(P)var_name}'"
    export "$var_name"
  }
    
  export_and_report "GMS_LOCAL_DIRECTORY"
  export_and_report "GMS_SCRIPTS"
  export_and_report "GMS_HYPERVISOR_SCRIPTS"

  # Updates the clone of GenoMac-system that is assumed to reside at GENOMAC_SYSTEM_LOCAL_DIRECTORY
  echo "Updating local clone of GenoMac-system"
  update_genomac_system_repo

  # Now that GenoMac-system has been updated, spawn the hypervisor that manages the bootstrapping/maintenance
  # of the system-scoped configuration

  function source_with_report() {
    # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
    #
    # Defining this function here solves a chicken-or-egg problem: We’d like to use the helper 
    # safe_source(), but it hasn’t been sourced yet. The current function is not quite as full functional 
    # but will do for the initial sourcing of helpers.
    local file="$1"
    if source "$file"; then
      echo "Sourced: $file"
    else
      echo "Failed to source: $file"
      return 1
    fi
  }

  initialization_script="$GMS_HYPERVISOR_SCRIPTS/0_initialize_me.sh"
  hypervisor_script="$GMS_HYPERVISOR_SCRIPTS/run_hypervisor.sh"
  source_with_report "$initialization_script"
  source_with_report "$hypervisor_script"
  unfunction source_with_report
  unfunction export_and_report

  run_hypervisor

  echo "Leaving alphahypervisor"

}

function update_genomac_system_repo() {
  if [[ ! -d ~/.genomac-system || -z "$(ls -A ~/.genomac-system 2>/dev/null)" ]]; then
    echo "You must clone the GenoMac-system repo to ${GENOMAC_SYSTEM_LOCAL_DIRECTORY} before running the Hypervisor"
    return 1
  fi
  cd "${GENOMAC_SYSTEM_LOCAL_DIRECTORY}"
  git pull --recurse-submodules origin main
}
