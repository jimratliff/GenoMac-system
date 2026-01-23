#!/usr/bin/env zsh

set -euo pipefail

function sentinel_of_the_hypervisor() {
  # This is the function called first, directly, and immediately by `make hypervisor-run`.
  #
  # It assumes that GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # It is *not* necessary to update the clone before running this function, because this function updates the clone.
  #
  # Side effects:
  # - Exports
  #   - GMS_LOCAL_DIRECTORY="$HOME/.genomac-system"
  #   - GMS_SCRIPTS="${GMS_LOCAL_DIRECTORY}/scripts"
  #   - GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"

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
  update_genomac_system_repo

  # Now that GenoMac-system has been updated, spawn the hypervisor that manages the bootstrapping/maintenance
  # of the system-scoped configuration

  hypervisor_script="$GMS_HYPERVISOR_SCRIPTS/run_hypervisor.sh"
  if source "$hypervisor_script"; then
    echo "Sourced: $hypervisor_script"
  else
    return "Failed to source: $hypervisor_script"
    return 1
  fi
  
  run_hypervisor

  unfunction source_with_report
  unfunction export_and_report
}

function update_genomac_system_repo() {
  if [[ ! -d ~/.genomac-system || -z "$(ls -A ~/.genomac-system 2>/dev/null)" ]]; then
    echo "You must clone the GenoMac-system repo to ${GENOMAC_SYSTEM_LOCAL_DIRECTORY} before running the Hypervisor"
    return 1
  fi
  cd "${GENOMAC_SYSTEM_LOCAL_DIRECTORY}"
  git pull --recurse-submodules origin main
}
