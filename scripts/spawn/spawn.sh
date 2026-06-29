#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-addUser.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-default_attributes_for_user_configurer.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-interactive.sh"
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
  # without error. However, if a specified user-to-create has a novel short name but has a uid that
  # corresponds to an existing user, a fatal error is raised.
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
  # Conditionally creates a single user account, specified by user_spec_json, which is passed as the first of four arguments.
  # (The user is created only if there is no user with the short name specified by user_spec_json. A uid collision is a 
  # fatal error.)
  # Sets system-scoped states to record:
  # - that the user has been created
  # - that the user is in need of initial configuration
  # - each of the attributes of the user
  # - that the volume (if non-startup) needs to be created/encrypted by a particular passphrase
  #   referenced by name of item in 1Password vault
  #
  # If the user already exists, the user attributes associated with the user are nevertheless re-read and re-implemented.
  # This allows the set of user attributes for a user to be updated even after the user is created.
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
    report_fail "Proposed uid $uid for user $short_name already exists as one (or more) different user(s):${NEWLINE}${conflicting_short_names}"
    return 1
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
  
  sysadminctl_adduser \
    --short-name             "$short_name" \
    --full-name              "$full_name" \
    --uid                    "$uid" \
    --home                   "$home_directory" \
    --avatar-path            "$avatar_path" \
    --admin-user-name        "$admin_user_name" \
    --hint                   "User class: $user_class" \
    --op-vault               "$op_vault" \
    --op-item-user-password  "$op_item_user_password" \
    --op-item-admin-password "$op_admin_password_item_name"

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



############### Below this line, the code is DEPRECATED

#  function create_local_user_account() {
#    local name="$1"
#    local uid="$2"
#    local user_class="$3"
#    local avatar_rel="$4"
#  
#    local vol="${VOC_VOL[$vocation]:-}"
#    [[ -n "$vol" ]] || { report "ERROR: user-class '$user_class' has no mapped volume"; exit 1; }
#  
#    local pass="${VOL_PASS[$vol]:-}"
#    [[ -n "$pass" ]] || { report "ERROR: volume '$vol' has no passphrase provided"; exit 1; }
#  
#    local shortname="$name"
#    local home="/Volumes/${vol}/Users/${name}"
#  
#    # Strict guards (initialize-only)
#    if id -u "$shortname" >/dev/null 2>&1; then
#      report "ERROR: user '$shortname' already exists; refusing to modify on pristine init"
#      exit 1
#    fi
#    
#    if dscacheutil -q user | awk -v target="$uid" '$1=="uid:" && $2==target {found=1} END{exit(found?0:1)}'; then
#      report "ERROR: UID '$uid' is already in use; refusing to proceed"
#      exit 1
#    fi
#  
#    report_action_taken "Creating user '$name' (uid=$uid, vocation=$vocation, volume=$vol)"
#  
#    run "mkdir -p '$home'"; success_or_not
#  
#    # Resolve avatar path relative to GENOMAC_USER_LOGIN_PICTURES_DIRECTORY (optional)
#    local avatar_abs=""
#    local picture_flag=""
#    if [[ -n "${avatar_rel}" ]]; then
#      avatar_abs="${GENOMAC_USER_LOGIN_PICTURES_DIRECTORY%/}/${avatar_rel}"
#      if [[ -f "$avatar_abs" ]]; then
#        picture_flag="-picture \"$avatar_abs\""
#      else
#        report "  - Avatar file not found at '$avatar_abs'; user will have the default picture"
#      fi
#    else
#      report "  - No avatar filename provided; user will have the default picture"
#    fi
#  
#    # Create user with UID, home, shell, picture; feed password via stdin (kept off argv)
#    # Note: many systems accept `-password -` to read from stdin; we keep that pattern.
#    local add_cmd="printf %s \"\${pass}\" | sysadminctl -addUser \"$shortname\" \
#      -fullName \"$name\" \
#      -UID \"$uid\" \
#      -home \"$home\" \
#      ${picture_flag} \
#      -password -"
#    run "$add_cmd"; success_or_not
#  
#    # Ensure ownership of the home directory
#    run "chown -R '$shortname':staff '$home'"; success_or_not
#  }

#  function prompt_configurer_to_supply_login_pictures_if_desired() {
#    # Asks USER_CONFIGURER whether login pictures are desired when creating user accounts. If so, 
#    # prompts USER_CONFIGURER to confirm that the desired login pictures reside in USER_PICTURE_DIRECTORY
#    # If login pictures are desired, but their existence isn’t confirmed by USER_CONFIGURER, 
#    # the user-creation process is aborted.
#    
#    report_start_phase_standard
#  
#    if ! get_yes_no_answer_to_question "Do you want the new users to be specified with login pictures?"; then
#      report "I won’t create a directory for login pictures, since you don’t want to use them"
#    report_end_phase_standard
#      return 0
#    fi
#  
#    report_action_taken "Creating, if necessary, directory for users’ login pictures"
#    mkdir -p "$USER_PICTURE_DIRECTORY" ; success_or_not
#  
#    report "The login picture for each user must be in: $USER_PICTURE_DIRECTORY"
#    report_action_taken "I am opening this directory for you to inspect its contents"
#    open "$USER_PICTURE_DIRECTORY" ; success_or_not
#    if ! get_yes_no_answer_to_question "Answer “yes” if you’re satisfied the login pics are in the folder. Answer “no” to cancel."; then
#      report "You want login pictures, but you haven’t confirmed you’ve supplied them.${NEWLINE}I am aborting. Feel free to try again later."
#      return 1
#    fi
#  
#    report_success "You have confirmed the existence of the desired login pictures. Moving on to create new users."
#    
#    report_end_phase_standard
#  }
