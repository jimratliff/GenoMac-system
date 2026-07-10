#!/usr/bin/env zsh

############### REFACTORING IN PROGRESS (7/10/2026) WARNING ###############
# Previously (as memorialized in the secure-token-for-all branch), all new users were given
# a Secure Token, enabling them to unlock the FileVault-protected startup volume.
# However, this power is useless for users whose home directory resides on a different and
# encrypted volume. This refactoring changes the policy such that only users who reside
# on the startup volume receive a Secure Token.
#
# Also previously, allowed a cleartext alternative to 1Password. That is being removed.

function sysadminctl_adduser() {
  # An interface to the addUser subcommand of sysadminctl.
  #
  # Creates a new user via sysadminctl -addUser, conditionally enabling Secure Token if
  # --give-secure-token.
  #
  # sysadminctl is called with sudo. (The --admin-user-name is for an admin user with a
  # Secure Token. It doesn’t provide authority to create a user without sudo.)
  # 
  # Intended usage: Provide the password for (a) the new user and (b) if --give-secure-token,
  # an existing admin user with a Secure Token, by providing the name of a
  # 1Password vault and the name of the password items in that vault that contain those two
  # passwords. (This reduces the security exposure relative to passing cleartext passwords
  # between functions.)
  #
  # If --give-secure-token, this function requires credentials for an existing admin user
  # with a Secure Token, referred to as the “authorizing admin.”
  #
  # The new user is referred to as “user,” even though that user is also by default an 
  # admin-level user.
  #
  # If --give-secure-token, after creation, this function confirms that Secure Token is
  # enabled for the new user. If Secure Token is not confirmed to be enabled, the function fails.
  #
  # NOTE: The --home path does *not* need to exist in order for the user to be created.
  #       The *volume* will need to exist and be mounted when this user first logs into the account.
  #       However, the /Users directory need not exist when the user first logs into the
  #       account. It will be created along with the user’s home directory at that time.
  #
  # Parameters:
  #   --short-name                mandatory  <string> short user name for new user
  #   --full-name                 optional   <string> full user name for new user
  #   --uid                       mandatory  <integer> UID for new user
  #   --home                      mandatory  <string> full path to home directory
  #   --op-vault                  mandatory  <string> 1Password vault name
  #   --op-item-user-password     mandatory  <string> item name containing password for --short-name
  #   --avatar-path               optional   <string> full path to avatar file
  #   --hint                      optional   <string> password hint
  #   --not-an-admin              optional   If supplied, new user will NOT be an admin.
  #                                          Default: new user WILL be an admin.
  #   --give-secure-token         optional   If supplied, new user will be give Secure Token.
  #
  #   The following are mandatory only if --give-secure-token is provided:
  #   --admin-user-name                      <string> short name of existing admin user
  #   --op-item-admin-password               <string> item name containing password for --admin-user-name

  report_start_phase_standard
  report_argument_vector "$@"

  local short_name=""
  local full_name=""
  local uid=""
  local home=""
  local op_vault=""
  local op_item_user_password=""
  local avatar_path=""
  local hint=""
  local new_user_is_admin=true

  local do_give_secure_token=false
  local admin_user_name=""
  local op_item_admin_password=""

  local user_password=""
  local admin_password=""

  local -a cmd

  while (( $# > 0 )); do
    case "$1" in
      --short-name)
        short_name=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --full-name)
        full_name=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --uid)
        uid=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --home)
        home=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --op-vault)
        op_vault=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --op-item-user-password)
        op_item_user_password=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --avatar-path)
        avatar_path=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --hint)
        hint=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --not-an-admin)
        new_user_is_admin=false
        shift
        ;;
      --give-secure-token)
        do_give_secure_token=true
        shift
        ;;
      --admin-user-name)
        admin_user_name=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      --op-item-admin-password)
        op_item_admin_password=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      *)
        report_fail "Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  require_mandatory_parameters \
    short_name            --short-name \
    uid                   --uid \
    home                  --home \
    op_vault              --op-vault \
    op_item_user_password --op-item-user-password

  ############### TODO
  # Add tests that:
  # - if "$do_give_secure_token" == true, then both (a) admin_user_name and
  #   (b) op_item_admin_password must have been specified
  # - if NOT do_give_secure_token=true, then NEITHER (a) admin_user_name and
  #   nor (b) op_item_admin_password have been specified

  # Use supplied 1Password key name for user password to retrieve the actual password
  if ! user_password="$(read_1password_item_password "$op_vault" "$op_item_user_password")"; then
    report_fail "Failed to retrieve the new user's password from 1Password."
    return 1
  fi

  # Build the sysadminctl command as an array

  cmd=(
    sudo sysadminctl
    -addUser "$short_name"
    -UID "$uid"
    -password "$user_password"
    -home "$home"
  )

  if [[ -n "$full_name" ]]; then
    cmd+=(-fullName "$full_name")
  fi

  if [[ -n "$hint" ]]; then
    cmd+=(-hint "$hint")
  fi

  if [[ -n "$avatar_path" ]]; then
    cmd+=(-picture "$avatar_path")
  fi

  if [[ "$new_user_is_admin" == true ]]; then
    cmd+=(-admin)
  fi

  if [[ "$do_give_secure_token" == true ]]; then
    # Use supplied 1Password key name for Secure Token–holding admin password to retrieve the actual password
    if ! admin_password="$(read_1password_item_password "$op_vault" "$op_item_admin_password")"; then
      report_fail "Failed to retrieve the admin user's password from 1Password."
      return 1
    fi

    # Add arguments to achieve Secure Token
    cmd+=(-adminUser "$admin_user_name")
    cmd+=(-adminPassword "$admin_password")
  fi

  report "About to create user ${short_name} with home directory ${home}."

  if [[ "$new_user_is_admin" == true ]]; then
    report "New user will be created as an admin user."
  else
    report "New user will be created as a standard user."
  fi

  # Note: Do not log/print the full command, because it contains passwords in argv.
  # Execute constructed command and test its success
  if ! "${cmd[@]}"; then
    report_fail "sysadminctl failed while creating user ${short_name}."
    return 1
  fi

  if [[ "$do_give_secure_token" == true ]]; then
    if confirm_secure_token_was_enabled_for_user "$short_name"; then
      report_success "User ${short_name} was created and Secure Token was enabled."
    else
      report_fail "User ${short_name} was created, but Secure Token was not confirmed enabled."
      return 1
    fi
  else
    if confirm_secure_token_was_enabled_for_user "$short_name"; then
      report_warning "A Secure Token was enabled for User ${short_name} even though that was not desired."
    else
      report_success "User ${short_name} was created and, as desired, Secure Token wasn’t enabled."
      return 0
    fi
  fi

  report_end_phase_standard
}
