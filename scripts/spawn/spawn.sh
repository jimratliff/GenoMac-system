#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-addUser.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-default_attributes_for_user_configurer.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-helpers.sh"
# safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-interactive.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-state-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-creation.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-creation-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-state-helpers.sh"

# Global associative arrays to be populated from GenoMac-spawn/spawn/user-spawn-config.json
#
# NOTE: Formerly, this was: “to be populated from item OP_ITEM_NAME_USER_SPAWN_CONFIG of 1Password vault
# OP_VAULT_FOR_GENOMAC_USER_CREATION”

typeset -gA volume_name_from_user_class
typeset -gA onepassword_key_from_user_class
typeset -gA user_attributes_from_user_class

function conditionally_create_user_accounts_for_this_Mac() {
  # Creates user accounts specified in users_to_create JSON object, which is read from GenoMac-private,
  # making use of nonlocal associative arrays volume_name_from_user_class, onepassword_key_from_user_class,
  # and user_attributes_from_user_class, where these specifications are also read from GenoMac-private.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which user already exists, as does
  # a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  # users.
  #
  # If a specified user-to-create has a short name that already has a user account, that user is skipped
  # without error. If a specified user-to-create has a novel short name but has a uid that
  # corresponds to an existing user, creation of this user is skipped and a warning message is issued.
  #
  # If a specified user-to-create resides on the startup volume, that user will be given a Secure Token
  # to allow it to unlock the FileVault-protected startup volume. If a specified user-to-create resides
  # on a different volume, that user will not be given a Secure Token (in hopes that that user’s avatar
  # will not show up on the login screen when the Mac first boots up).
  #
  # See scripts/spawn/0_README.md for a description of:
  # - the users_to_create JSON object
  # - the volume_name_from_user_class associative array
  # - the onepassword_key_from_user_class associative array
  # - the user_attributes_from_user_class associative array
  #
  # This function assumes, among other things, that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  # - The following environment variables have been defined:
  #   - DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES   ("/Users")
  #   - OP_ITEM_NAME_AUTHORIZING_ADMIN_USER_NAME     ("authorizing-admin-user-name")
  #   - OP_ITEM_NAME_AUTHORIZING_ADMIN_USER_PASSWORD ("SUPERINTENDENT_PASSWORD")
  #   - OP_VAULT_FOR_GENOMAC_USER_CREATION           ("GenoMac-user-creation")
  #   - OP_VAULT_FOR_GENOMAC_PRIVATE_GITHUB_PAT      ("GenoMac-user-creation")
  #   - OP_ITEM_NAME_GENOMAC_PRIVATE_GITHUB_PAT      ("GitHub_PAT_GenoMac-private_read-only")
  
  report_start_phase_standard

  local admin_user_name
  local op_admin_password_item_name
  local op_vault
  local user_spec_json
  local users_to_create_json
  
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  report "Sign into 1Password (if necessary)"
  op signin

  # Populate associative arrays (a) volume_name_from_user_class, (b) onepassword_key_from_user_class,
  # and (c) user_attributes_from_user_class by reading from GeoMac-private/spawn/user-spawn-config.json.
  # These arrays are *not* local, because they are referenced by functions called later by this function.
  get_user_spawn_config_associative_arrays

  # Gets credentials for the existing user (admin level, with a Secure Token) required to bestow a
  # Secure Token upon each new to-be-created user.
  op_vault="$OP_VAULT_FOR_GENOMAC_USER_CREATION"
  admin_user_name="$(read_1password_item_notes_plain "$op_vault" "$OP_ITEM_NAME_AUTHORIZING_ADMIN_USER_NAME")"
  op_admin_password_item_name="$OP_ITEM_NAME_AUTHORIZING_ADMIN_USER_PASSWORD"

  # Get JSON object specifying users to create from GenoMac-private/spawn/specs-of-users-to-create.json
  # This JSON object is *not* local, because it is referenced by functions called later within this shell
  users_to_create_json="$(get_users_to_create_from_GenoMac_private)"

  # Iterate through users_to_create_json, user by user
  keep_sudo_alive
  while IFS= read -r user_spec_json; do
    conditionally_create_user_account "$user_spec_json" "$op_vault" "$admin_user_name" "$op_admin_password_item_name"
  done < <(jq -c '.users_to_create[]' <<<"$users_to_create_json")

  report_end_phase_standard
}

function conditionally_create_user_account(){
  # Conditionally creates a single user account, specified by user_spec_json, which is passed
  # as the first of four arguments.
  # 
  # If the user’s short name already exists, creation is skipped and returns normally. Thus,
  # conditionally_create_user_account can be run idempotently in the sense that only newly
  # added users will be created. (This isn’t purely declarative: A user removed from the
  # specification will *not* be *uncreated*.)
  #
  # If the new user’s uid collides with an existing uid, creation is skipped and a warning is
  # issued that the uid must be changed and “resubmitted” (i.e., rerun Hypervisor-system).
  # 
  # Sets system-scoped states to record:
  # - that the user has been created
  # - that the user is in need of initial configuration
  # - each of the attributes of the user
  # - that the volume (if non-startup) needs to be created/encrypted by a particular passphrase
  #   referenced by name of item in 1Password vault
  #
  # If the user already exists, the user attributes associated with the user are nevertheless
  # re-read and re-implemented. This allows the set of user attributes for a user to be updated
  # even after the user is created.
  #
  # Relies on associative arrays volume_name_from_user_class, onepassword_key_from_user_class
  # and user_attributes_from_user_class being available and populated by caller.

  report_start_phase_standard
  local user_spec_json="${1:?MISSING user_spec_json}"
  local op_vault="${2:?MISSING op_vault}"
  local admin_user_name="${3:?MISSING admin_user_name}"
  local op_admin_password_item_name="${4:?MISSING op_admin_password_item_name}"

  local avatar
  local avatar_path
  local conflicting_short_names
  local full_name
  local home_directory
  local op_item_user_password
  local parent_of_home_directory
  local short_name
  local uid
  local user_class
  local volume_name
  local warning_message

  # Set states for user attributes for this user BEFORE the user is created and BEFORE the
  # check whether this user already exists. This way, this function will update the user’s
  # attributes every time GenoMac-system’s Hypervisor is run, even if the user has already
  # been created.
  set_system_states_for_user_attributes_of_user "$user_spec_json" # scripts/spawn/spawn-state-helpers.sh
  
  short_name="$(get_short_name_from_user_spec_json "$user_spec_json")"
  if does_user_name_exist "$short_name"; then
    report_warning "User “$short_name” already exists; skipping creation of this user."
    report_end_phase_standard
    return 0
  fi

  full_name="$(get_full_name_from_user_spec_json "$user_spec_json")"
  
  uid="$(get_uid_from_user_spec_json "$user_spec_json")"
  if does_user_uid_exist $uid; then
    conflicting_short_names="$(string_of_short_names_with_uid $uid)"
    warning_message="Proposed uid $uid for user $short_name already exists as one (or more) different user(s):"
    warning_message+="${NEWLINE}${conflicting_short_names}"
    warning_message+="${NEWLINE}Please provide a unique uid for user $short_name and rerun Hypervisor-system."
    warning_message+="${NEWLINE}Skipping creation of user ${short_name}."
    report_warning "$warning_message"
    return 0
  fi

  avatar="$(get_avatar_subpath_from_user_spec_json "$user_spec_json")"
  
  if [[ -n "$avatar" ]]; then
    avatar_path="${USER_PICTURE_DIRECTORY}/${avatar}"
  else
    avatar_path=""
  fi
  
  user_class="$(get_user_class_from_user_spec_json "$user_spec_json")"
  op_item_user_password="${onepassword_key_from_user_class[$user_class]}"

  volume_name="${volume_name_from_user_class[$user_class]}"
  parent_of_home_directory="$(parent_of_users_home_directories "$volume_name")"    # scripts/spawn/spawn-helpers.sh
  home_directory="${parent_of_home_directory}/${short_name}"

  if is_supplied_HOME_too_long_for_1P_SSH_Agent_socket "$home_directory"; then
    warning_message="Home directory path is too long for 1Password SSH Agent configuration."
    warning_message+="${NEWLINE}Skipping creation of user ${short_name}."
    warning_message+="${NEWLINE}Denying creation in this circumstance is current policy."
    report_warning "$warning_message"
    return 0
  fi
  
  ############### BEGIN: Interactively confirm that this user should be created at this time

  local user_creation_mode
  report "I’m on the verge of creating user “${short_name}” on ${home_directory}"
  user_creation_mode="$(get_value_from_numbered_choices \
    "How do you want to deal with the pending-to-create user “$short_name”?" \
    "Create this user now" "CREATE_NOW" \
    "PUNT. Leave it pending for now, move on, and I’ll deal with it later" "PUNT" \
    "ABORT. Abort now; don’t show me any other pending users to create at this time." "ABORT"
    )"

  case "$user_creation_mode" in
    CREATE_NOW)
      # Create this user now
      # Fall through the case switch
      ;;
    
    PUNT)
      #  Leave it pending for now, move on, and I’ll deal with it later
      report_warning "You have deferred the creation of user “$short_name”."
      report_end_phase_standard
      return 0
      ;;
    
    ABORT)
      # Abort now; don’t show me any other pending users to create at this time
      leave_genomac_hypervisor "At your direction, I am aborting."
      ;;
    
    *)
      report_fail "Unrecognized user-creation choice: “${user_creation_mode}”"
      return 1
      ;;
  esac

  ############### END: Interactively confirm that this user should be created at this time

  # Prepare arguments for, and then execute, sysadminctl_adduser
  
  local -a sysadminctl_adduser_args
  
  sysadminctl_adduser_args=(
    --short-name             "$short_name"
    --full-name              "$full_name"
    --uid                    "$uid"
    --home                   "$home_directory"
    --avatar-path            "$avatar_path"
    --hint                   "User class: $user_class"
    --op-vault               "$op_vault"
    --op-item-user-password  "$op_item_user_password"
  )
  
  # Give a Secure Token only when user’s home directory resides on startup volume
  if volume_name_is_startup_volume_signifier "$volume_name"; then
    report_to_log "Adding Secure Token for this user (“${short_name}”) residing on startup volume."
    sysadminctl_adduser_args+=(
      --give-secure-token
      --admin-user-name        "$admin_user_name"
      --op-item-admin-password "$op_admin_password_item_name"
    )
  else
    report_to_log "No Secure Token for this user (“${short_name}”) residing on non-startup volume."
  fi
  
  sysadminctl_adduser "${sysadminctl_adduser_args[@]}"

  # Post–user-creation bookkeeping

  mark_user_as_created "$short_name" "$volume_name"                                # scripts/spawn/spawn-state-helpers.sh
  mark_user_as_in_need_of_initial_config "$short_name"                             # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh
  conditionally_mark_volume_is_necessary "$volume_name" "$op_item_user_password"   # scripts/spawn/spawn-volume-state-helpers.sh
  
  report_end_phase_standard
}

function get_user_spawn_config_associative_arrays() {
  # Get values for associative arrays (a) volume_name_from_user_class,
  # (b) onepassword_key_from_user_class, and (c) user_attributes_from_user_class from
  # JSON object in GenoMac-private/spawn/user-spawn-config.json

  report_start_phase_standard
  local user_spawn_config_json

  # Get JSON from GenoMac-private
  # get_user_spawn_config_from_GenoMac_private is defined in scripts/spawn/spawn-helpers.sh
  if ! user_spawn_config_json="$(get_user_spawn_config_from_GenoMac_private)"; then
    report_fail "Failed to retrieve user spawn config from GenoMac-private."
    return 1
  fi

  # Get associative arrays from JSON
  if ! populate_user_spawn_associative_arrays_from_json <<<"$user_spawn_config_json"; then
    report_fail "Failed to populate user spawn associative arrays from JSON."
    return 1
  fi

  report_end_phase_standard
}
