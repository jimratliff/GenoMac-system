#!/usr/bin/env zsh

function conditionally_mark_this_user_needs_initial_configuration() {
  # Marks USER_CONFIGURER as needing initial configuration by GenoMac-user, if this hasn’t already been marked.
  # This is necessary as an explicit step because (a) Hypervisor-System automatically marks as needing initial
  # configuration only new users that Hypervisor-System has created and (b) USER_CONFIGURER is not created by
  # GenoMac-system but rather preexists in order to run Hypervisor-System.
  
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_USER_CONFIGURER_HAS_BEEN_MARKED_AS_NEEDING_INITIAL_CONFIGURATION" \
    mark_current_user_as_in_need_of_initial_config \
    "Skipping marking USER_CONFIGURER as needing initial configuration, because this was marked in the past."
    
  report_end_phase_standard
}

function conditionally_exit_for_user_configurer_to_configure_itself() {
  # If USER_CONFIGURER hasn’t yet been configured using GenoMac-user, exit to allow USER_CONFIGURER to use
  # GenoMac-user to do so.
  report_start_phase_standard

  local instruction_message="You must now use GenoMac-user to configure this current user account.${NEWLINE}I’ve opened a document explaining this process."

  if ! test_whether_current_user_is_in_need_of_initial_config; then
    report_to_log "USER_CONFIGURER isn’t in need of initial configuration. Moving on…"
    report_end_phase_standard
    return 0
  fi

  print_banner_text "HALT! Switch repos!"
  launch_app_and_prompt_user_to_act \
    --show-doc "${GMS_DOCS_TO_DISPLAY}/USER_CONFIGURER_how_to_configure.md" \
    --no-app \
    "$instruction_message"
  report warning "$instruction_message"
  report warning "You will now EXIT this shell."
  report_end_phase_standard
  exit 0
}

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
