#!/usr/bin/env zsh

function interactive_get_parent_of_users_home_directories() {
  # Return path of parent directory of users’ home directory based on interactive input.
  #
  # Asks to choose between whether the volume is (a) the startup volume or (b) another volume.
  # If another volume, asks to supply a volume name.
  report_start_phase_standard
  local option=""
  local volume_name=""
  local parent=""
  
  option="$(
    get_value_from_numbered_choices \
      "Choose an option for the volume on which the users’ home directories live:" \
      "This is the startup volume" "IS_STARTUP_VOLUME" \
      "This is other than the startup volume" "OTHER_VOLUME"
  )"

  case "$option" in
    "IS_STARTUP_VOLUME")
      parent="$(parent_of_users_home_directories --startup-volume)"
      ;;
    "OTHER_VOLUME")
      volume_name="$(get_nonblank_answer_to_question "Non-startup volume name")"
      parent="$(parent_of_users_home_directories --volume-name "$volume_name")"
      ;;
    *)
      report_fail "PROGRAMMER ERROR: Unexpected option: ${option}"
      return 1
      ;;
  esac
  report "Parent of users’ home directories: $parent"
  print -- "$parent"
  report_end_phase_standard
}

function interactive_test_of_parent_of_users_home_directories() {
  # Iterative interactive test for interactive_get_parent_of_users_home_directories
  local parent=""

  report "For each choice of volume you make, I’ll return the path of the${NEWLINE}parent of the home directories on that volume."
  while true; do
    interactive_get_parent_of_users_home_directories || return 1
    report "Type ⌃C to stop"
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
  # - Asks for either (a) this is on the startup volume or (b) a particular other volume.
  
  report_start_phase_standard
  local user_short_name=""
  local user_full_name=""
  local uid=""
  local home=""
  local parent_of_home=""
  local avatar_path=""
  local onepassword_user_password_item_name=""
  local onepassword_admin_password_item_name=""
  local cleartext_user_password=""
  local cleartext_admin_password=""
  local admin_user_short_name=""
  local passphrase_mode=""
  local hint=""
  local -a adduser_args
  adduser_args=()

  user_short_name="$(get_nonblank_answer_to_question "User short name")"
  adduser_args+=(--short-name "$user_short_name")
  
  uid="$(get_nonblank_answer_to_question "User uid (suggest 510–999)")"
  adduser_args+=(--uid "$uid")
  
  user_full_name="$(get_nonblank_answer_to_question "User FULL name (or “none”)")"
  [[ "${user_full_name:l}" == "none" ]] && user_full_name=""
  adduser_args+=(--full-name "$user_full_name")
  
  admin_user_short_name="$(get_nonblank_answer_to_question "Admin-user short name")"
  adduser_args+=(--admin-user-name "$admin_user_short_name")
  
  parent_of_home="$(interactive_get_parent_of_users_home_directories)"
  home="${parent_of_home}/${user_short_name}"
  adduser_args+=(--home "$home")
  
  avatar_path="$(get_nonblank_answer_to_question "Avatar path (or “none”)")"
  [[ "${avatar_path:l}" == "none" ]] && avatar_path=""
  adduser_args+=(--avatar-path "$avatar_path")

  passphrase_mode="$(get_value_from_numbered_choices \
    "How do you want to supply passwords (for the new user and authorizing admin user)?" \
    "Use named items in the “${ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION}” 1Password vault" "1PASSWORD" \
    "Clear text" "CLEAR_TEXT"
    )"

  case "$passphrase_mode" in
    "1PASSWORD")
      adduser_args+=(--op-vault "$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION")
      report "Enter the name of the 1Password ITEMs from the “${ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION}” 1Password vault for the following passwords:"
      onepassword_user_password_item_name="($get_nonblank_answer_to_question "Name of 1Password ITEM for NEW USER")"
      adduser_args+=(--op-item-user-password "$onepassword_user_password_item_name")
      onepassword_admin_password_item_name="($get_nonblank_answer_to_question "Name of 1Password ITEM for the AUTHORIZING ADMIN USER")"
      adduser_args+=(--op-item-admin-password "$onepassword_admin_password_item_name")
      ;;
    "CLEAR_TEXT")
      report "Enter the cleartext passwords for the following users:"
      cleartext_user_password="($get_nonblank_answer_to_question "Cleartext password for NEW USER")"
      adduser_args+=(--cleartext-password-user "$cleartext_user_password")
      cleartext_admin_password="($get_nonblank_answer_to_question "Cleartext password for AUTHORIZING ADMIN USER")"
      adduser_args+=(--cleartext-password-admin "$cleartext_admin_password")
      ;;
    *)
      report_fail "PROGRAMMER ERROR: Unexpected passphrase mode: ${passphrase_mode}"
      return 1
      ;;
  esac

  hint="$(get_nonblank_answer_to_question "Hint for new-user password (or “none”)")"
  [[ "${hint:l}" == "none" ]] && hint=""
  adduser_args+=(--hint "$hint")

  if ! get_yes_no_answer_to_question "Should the new user have admin-level rights?"; then
    adduser_args+=(--not-an-admin)
  fi

  report "I’m this close to creating the new user, but first let me show you the arguments I have:"
  report_argument_vector adduser_args

  if ! get_yes_no_answer_to_question "Continue to create the new user? (If not, I’ll stop)"; then
    report "Aborting at your request"
    return 1
  fi
  
  report_action_taken "Creating new user"
  sysadminctl_adduser "${adduser_args[@]}"
  success_or_not
  report_end_phase_standard
}
