#!/usr/bin/env zsh

function interactive_test_of_parent_of_users_home_directories_from_volume_name() {
  # Interactive front end for parent_of_users_home_directories_from_volume_name
  report_start_phase_standard
  local volume_name=""

  report "I will test, for each user you specify, whether that user exists."

  while true; do
    volume_name=$(get_nonblank_answer_to_question "Volume name or “stop”")

    if [[ "${volume_name:l}" == "stop" ]]; then
      report_end_phase_standard
      return 0
    fi

    home_directory="$(parent_of_users_home_directories_from_volume_name "$volume_name")"

    report "Home-directory path: $home_directory"

  done
}

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
  local onepassword_item_name=""
  local passphrase_mode=""
  local volume_name=""
  local -a ensure_volume_args
  ensure_volume_args=()

  if get_yes_no_answer_to_question "Do you want to use the startup-volume container?"; then
    ensure_volume_args+=(--startup-container)
  else
    container_name=$(get_confirmed_answer_to_question "Name of container?")
    ensure_volume_args+=(--container "$container_name")
  fi

  volume_name=$(get_confirmed_answer_to_question "Name of volume?")
  ensure_volume_args+=(--volume-name "$volume_name")

  passphrase_mode=$(
    get_value_from_numbered_choices \
      "Choose a passphrase mode for supplying the passphrase" \
      "Interactively" "INTERACTIVE" \
      "From a named item in the “${ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION}” vault from 1Password" "1PASSWORD"
  )
  
  case "$passphrase_mode" in
    "INTERACTIVE")
      ensure_volume_args+=(--interactive-passphrase)
      ;;
    "1PASSWORD")
      onepassword_item_name=$(get_confirmed_answer_to_question "Name of 1Password item (in the “${ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION}” vault)?")
      ensure_volume_args+=(--op-vault "${ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION}")
      ensure_volume_args+=(--op-item-passphrase "${onepassword_item_name}")
      ;;
    *)
      report_fail "Unknown passphrase mode: $passphrase_mode"
      return 1
      ;;
  esac

  ensure_encrypted_apfs_volume_exists "${ensure_volume_args[@]}"
  
  report_end_phase_standard
}

function interactive_adduser() {
  # Interactive front end for sysadminctl_adduser().
  #
  # Mostly for testing purposes. Therefore, both more flexible and less flexible
  # than might be desired as a user-creation utility.
  #
  # - Allows for either interactive or 1Password password provision.
  # - Assumes the home directory will be created on some volume on the startup-volume
  #   container.
  #   - Asks for that volume name.
  
  report_start_phase_standard
  local user_short_name=""
  local user_full_name=""
  local uid=""
  local home=""
  local avatar_path=""
  local onepassword_user_password_item_name=""
  local onepassword_admin_password_item_name=""
  local admin_user_short_name=""
  local passphrase_mode=""
  local volume_name=""
  local -a adduser_args
  adduser_args=()

  user_short_name=$(get_nonblank_answer_to_question "User short name")
  uid=$(get_nonblank_answer_to_question "User uid (suggest 510–999)")
  
  user_full_name=$(get_nonblank_answer_to_question "User FULL name (or “none”")
  [[ "${user_full_name:l}" == "none" ]] && user_full_name=""
  
  admin_user_short_name=$(get_nonblank_answer_to_question "Admin-user short name")

  volume_name=$(get_nonblank_answer_to_question "Name of volume for user’s home directory")
  home=$(parent_of_users_home_directories_from_volume_name "volume_name")
  

  

  
  

  


}
