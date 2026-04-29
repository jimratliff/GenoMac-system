#!/usr/bin/env zsh

function interactive_test_for_user_existence() {
  # Interactive front end for iteratively running does_user_exist
  # Also runs confirm_secure_token_was_enabled_for_user

  report_start_phase_standard
  local user_short_name=""

  report "I will test, for each user you specify, whether that user exists."

  while true; do
    user_short_name=$(get_nonblank_answer_to_question "User short name or “stop”")

    if [[ "${user_short_name:l}" == "stop" ]]; then
      report_end_phase_standard
      return 0
    fi

    does_user_exist "$user_short_name" || true
    confirm_secure_token_was_enabled_for_user "$user_short_name" || true

    
  done
}

function interactive_ensure_encrypted_apfs_volume_exists() {
  # Interactive front end for ensure_encrypted_apfs_volume_exists
  
  report_start_phase_standard
  local container_name=""
  local use_startup_volume_container=false
  local volume_name=""
  local -a ensure_volume_args

  if ! get_yes_no_answer_to_question "Do you want to use the startup-volume container?"; then
    container_name=$(get_confirmed_answer_to_question "Name of container?")
  else
    use_startup_volume_container=true
  fi

  volume_name=$(get_confirmed_answer_to_question "Name of volume?")
  
  ensure_volume_args=(
    --volume-name "$volume_name"
    --interactive-passphrase
  )

  if [[ "$use_startup_volume_container" == true ]]; then
    ensure_volume_args+=(--startup-container)
  else
    ensure_volume_args+=(--container "$container_name")
  fi

  ensure_encrypted_apfs_volume_exists "${ensure_volume_args[@]}"
  
  report_end_phase_standard
}
