#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-addUser.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-default_attributes_for_user_configurer.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-interactive.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-state-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-creation-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-state-helpers.sh"

# Global associative arrays to be populated from item ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
# of 1Password vault ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
typeset -gA volume_name_from_user_class
typeset -gA onepassword_key_from_user_class
typeset -gA user_attributes_from_user_class

function conditionally_create_user_accounts_for_this_Mac() {
  # Creates user accounts specified in users_to_create_json JSON object, making use of nonlocal associative
  # arrays volume_name_from_user_class and onepassword_key_from_user_class, where these specifications are
  # stored securely in a 1Password vault.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which user already exists, as does
  # a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  # users.
  #
  # The users to be created are specified in a "users_to_create" JSON object stored in a plain-text item
  # of a 1Password vault. The script also references two associative arrays (a) volume_name_from_user_class
  # and (b)onepassword_key_from_user_class stored in a different plain-text item in the same 1Password
  # vault.
  #
  # If a specified user-to-create has a short name that already has a user account, that user is skipped
  # without error. However, if a specified user-to-create has a novel short name but has a uid that
  # corresponds to an existing user, a fatal error is raised.
  #
  # See scripts/spawn/0_README.md for a description of:
  # - the users_to_create JSON object
  # - the volume_name_from_user_class associative array
  # - the onepassword_key_from_user_class associative array
  #
  # This function assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  # - The following environment variables have been defined:
  #   - DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES            ("/Users")
  #   - ONEPASSWORD_ITEM_NAME_AUTHORIZING_ADMIN_USER_NAME     ("GenoMac-system-authorizing-admin-user-name")
  #   - ONEPASSWORD_ITEM_NAME_AUTHORIZING_ADMIN_USER_PASSWORD ("THE_STARTUP_PASSWORD")
  #   - ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE        ("GenoMac-system-specs-of-users-to-create")
  #   - ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG               ("GenoMac-system-user-spawn-config-json")
  #   - ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION           ("GenoMac-user-creation")
  
  report_start_phase_standard

  local admin_user_name
  local onepassword_admin_password_item_name
  local op_vault
  local user_spec_json
  
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  report "Sign into 1Password (if necessary)"
  op signin

  # Populate associative arrays volume_name_from_user_class and onepassword_key_from_user_class by reading
  # from plain-text item of 1Password vault.
  # These arrays are *not* local, because they are referenced by functions called later within this shell
  get_user_spawn_config_associative_arrays

  op_vault="$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION"
  admin_user_name="$(read_1password_item_notes_plain "$op_vault" "$ONEPASSWORD_ITEM_NAME_AUTHORIZING_ADMIN_USER_NAME")"
  onepassword_admin_password_item_name="$(read_1password_item_password "$op_vault" "$ONEPASSWORD_ITEM_NAME_AUTHORIZING_ADMIN_USER_PASSWORD")"

  # Get JSON object specifying users to create from plain-text item in 1Password vault
  # This JSON object is *not* local, because it is referenced by functions called later within this shell
  users_to_create_json="$(get_users_to_create_from_1password)"

  # Iterate through users_to_create_json, user by user
  keep_sudo_alive
  while IFS= read -r user_spec_json; do
    create_user_account "$user_spec_json"
  done < <(jq -c '.users_to_create[]' <<<"$users_to_create_json")

  report_end_phase_standard
}

function create_user_account(){
  # Creates a single user account, specified by user_spec_json, which is passed as only argument.
  # Sets system-scoped states to record:
  # - that the user has been created
  # - that the user is in need of initial configuration
  # - each of the attributes of the user
  # - that the volume (if non-startup) needs to be created/encrypted by a particular passphrase
  #   referenced by name of item in 1Password vault
  #
  # Relies on associative arrays volume_name_from_user_class, onepassword_key_from_user_class
  # [[and user_attributes_from_user_class]] being available and populated by caller.

  report_start_phase_standard
  local user_spec_json="$1"

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
  
  short_name="$(get_short_name_from_user_spec_json "$user_spec_json")"
  if does_user_name_exist "$short_name"; then
    report_warning "User ($short_name) already exists; skipping creation of this user."
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
  avatar_path="${USER_PICTURE_DIRECTORY}/${avatar}"
  
  user_class="$(get_user_class_from_user_spec_json "$user_spec_json")"
  op_item_user_password="${onepassword_key_from_user_class[$user_class]}"

  volume_name="${volume_name_from_user_class[$user_class]}"
  parent_of_home_directory="$(parent_of_users_home_directories "$volume_name")"
  home_directory="${parent_of_home_directory}/${short_name}"
  
  sysadminctl_adduser \
    --short-name             "$short_name" \
    --full-name              "$full_name" \
    --uid                    "$uid" \
    --home                   "$home_directory" \
    --avatar-path            "$avatar_path" \
    --admin-user-name        "$admin_user_name" \
    --hint                   "$user_class" \
    --op-vault               "$op_vault" \
    --op-item-user-password  "$op_item_user_password" \
    --op-item-admin-password "$onepassword_admin_password_item_name"

  mark_user_as_created "$short_name" "$volume_name"       # scripts/spawn/spawn-state-helpers.sh
  mark_user_as_in_need_of_initial_config "$short_name"    # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh
  conditionally_mark_volume_is_necessary "$volume_name" "$op_item_user_password" # scripts/spawn/spawn-volume-state-helpers.sh
  set_system_states_for_user_attributes "$user_spec_json" # scripts/spawn/spawn-state-helpers.sh
  
  report_end_phase_standard
}

function get_user_spawn_config_associative_arrays() {
  # Get values for associative arrays (a) volume_name_from_user_class, (b) onepassword_key_from_user_class,
  # and (c) user_attributes_from_user_class from JSON object in plain-text item of 1Password vault.

  report_start_phase_standard
  local user_spawn_config_json

  # Get JSON from 1Password
  if ! user_spawn_config_json="$(get_user_spawn_config_from_1password)"; then
    report_fail "Failed to retrieve user spawn config from 1Password."
    return 1
  fi

  # Get associative arrays from JSON
  if ! populate_user_spawn_associative_arrays_from_json <<<"$user_spawn_config_json"; then
    report_fail "Failed to populate user spawn associative arrays from JSON."
    return 1
  fi

  report_end_phase_standard
}

function get_user_spawn_config_from_1password() {
  # Get plain-text item $ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG from 1Password vaule
  # $ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
  #
  # Hint: ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
  # Hint: ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG="GenoMac-system-user-spawn-config-json"

  report_start_phase_standard
  local user_spawn_config_json

  if ! user_spawn_config_json="$(
    read_1password_item_notes_plain "$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION" "$ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG"
  )"; then
    report_fail "Failed to read user spawn config from 1Password."
    return 1
  fi

  report_end_phase_standard
  print -- "$user_spawn_config_json"
}

function populate_user_spawn_associative_arrays_from_json() {
  report_start_phase_standard

  local json_input
  json_input="$(cat)"

  # NOTE: populate_associative_array_from_json_object_of_scalars() and
  # populate_associative_array_from_json_object_of_string_arrays() are
  # defined in GenoMac-shared/scripts/helpers-json.sh

  if ! populate_associative_array_from_json_object_of_scalars \
    "$json_input" \
    '.volume_name_from_user_class' \
    volume_name_from_user_class
  then
    report_fail "Failed to populate volume_name_from_user_class."
    return 1
  fi

  if ! populate_associative_array_from_json_object_of_scalars \
    "$json_input" \
    '.onepassword_key_from_user_class' \
    onepassword_key_from_user_class
  then
    report_fail "Failed to populate onepassword_key_from_user_class."
    return 1
  fi

  if ! populate_associative_array_from_json_object_of_string_arrays \
    "$json_input" \
    '.user_attributes_from_user_class' \
    user_attributes_from_user_class
  then
    report_fail "Failed to populate user_attributes_from_user_class."
    return 1
  fi

  report_end_phase_standard
}

function get_users_to_create_from_1password() {
  report_start_phase_standard
  local users_to_create_json

  if ! users_to_create_json="$(
  read_1password_item_notes_plain "$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION" "$ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE"
  )"; then
    report_fail "Failed to read users-to-create JSON from 1Password."
    return 1
  fi

  report_end_phase_standard
  print -- "$users_to_create_json"
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
