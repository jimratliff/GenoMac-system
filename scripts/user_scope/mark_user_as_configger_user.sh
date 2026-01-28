#!/usr/bin/env zsh

function conditionally_mark_user_as_configger_user() {
  report_start_phase_standard

  if ! test_user_state "$PERM_USER_THIS_USER_IS_A_USER_CONFIGGER"; then
    set_user_state "$PERM_USER_THIS_USER_IS_A_USER_CONFIGGER"
  
  run_if_system_has_not_done \
    "$PERM_USER_THIS_USER_IS_A_USER_CONFIGGER" \
    clone_genomac_user_repo_using_HTTPS \
    "Skipping cloning GenoMac-user, because this was done in the past."

  report_end_phase_standard
}

