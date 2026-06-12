#!/usr/bin/env zsh

function conditionally_clone_genomac_user_using_HTTPS() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_GENOMAC_USER_HAS_BEEN_CLONED" \
    clone_genomac_user_repo_using_HTTPS \
    "Skipping cloning GenoMac-user, because this was done in the past."

  report_end_phase_standard
}

function clone_genomac_user_repo_using_HTTPS() {
  # Clone GenoMac-user repo to GENOMAC_USER_LOCAL_DIRECTORY using HTTPS.
  #
  # If GenoMac-user is already cloned to GENOMAC_USER_LOCAL_DIRECTORY, sets the
  # $PERM_GENOMAC_USER_HAS_BEEN_CLONED state and returns normally.

  report_start_phase_standard

  clone_public_genomac_repo_using_HTTPS "$GENOMAC_USER_REPO_NAME" "$GENOMAC_USER_LOCAL_DIRECTORY"

  local status=$?

  if (( status == 0 )); then
    set_genomac_system_state "$PERM_GENOMAC_USER_HAS_BEEN_CLONED"
  fi

  report_end_phase_standard
  return "$status"
}
