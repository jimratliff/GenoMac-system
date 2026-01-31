#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_HYPERVISOR_SCRIPTS}/subdermis.sh"

function hypervisor() {
  # The outermost “dermal” layer of hypervisory supervison (the dermis). Ensures the 
  # GenoMac-system repository is updated before running the subdermal layer (subdermis). 
  #
  # Compares the local clone against the remote repo to determine whether there are unpulled
  # changes. If so, updates the local clone and restarts this script. Otherwise, hand
  # control off to the subdermal layer (subdermis). The next time through, still under the
  # same “session,” the local won’t be tested against the remote, and thus control will
  # pass immediately to subdermis.
  #
  # It assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  #   - It is *not* necessary to update the clone before running this function, because this function
  #     updates the clone.
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  
  report_start_phase_standard

  keep_sudo_alive

  if ! test_genomac_system_state "SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES"; then
  	report_action_taken "Testing remote copy of ${GENOMAC_SYSTEM_REPO_NAME} for changes"
  	if local_clone_was_updated_from_remote "$GENOMAC_SYSTEM_LOCAL_DIRECTORY"; then
      # The local clone was found to be behind the remote; local clone updated, and then
      # this script is re-executed.
      set_genomac_system_state "SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES"
      report_action_taken "Re-execute Hypervisor using updated repo code"
      report_end_phase_standard
      exec "$0"
	else
      set_genomac_system_state "SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES"
      report "Local clone of ${GENOMAC_SYSTEM_REPO_NAME} was up to date"
	fi
  else
    report_action_taken "Skipping test for changes to repo, because this has already been tested this session."
  fi

  # Run the subdermal layer of the hypervisor, which supervises the remainder of the process.
  subdermis

  # Reset SESH states for next session
  delete_all_system_SESH_states

  report_end_phase_standard
}

