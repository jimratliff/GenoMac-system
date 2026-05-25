#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-addUser.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-interactive.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-state-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-volume-creation-helpers.sh"

# Global associative arrays to be populated from item ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
# of 1Password vault ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
typeset -gA volume_name_from_user_class
typeset -gA onepassword_key_from_user_class

function create_user_accounts_for_this_Mac() {
  # Creates specific user accounts for this Mac.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which user already exists, as does
  #   a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  #   users.
  #
  # The users to be created are specified in a "users_to_create" JSON object.
  #
  # See scripts/spawn/0_README.md for a description of the "users_to_create" JSON object.
  #
  # This function assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  # - The following environment variables have been defined:
  #   - ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION      ("GenoMac-user-creation")
  #   - ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG          ("GenoMac-system-user-spawn-config-json")
  #   - ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE   ("GenoMac-system-specs-of-users-to-create")
  #   - DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES       ("/Users")
  
  report_start_phase_standard
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  report "Sign into 1Password (if necessary)"
  op signin

  get_user_spawn_config_associative_arrays
  
  users_to_create_json="$(get_users_to_create_from_1password)" || return 1

  keep_sudo_alive
  
  # prompt_configurer_to_supply_login_pictures_if_desired

  create_users


  # ############### TODO WORK IN PROGRESS

  report_end_phase_standard
}

function create_users() {
  report_start_phase_standard

	local user_spec_json
	local short_name
	local full_name
	local uid
	local user_class
	local avatar
	
	while IFS= read -r user_spec_json; do
	  short_name="$(get_short_name_from_user_spec_json "$user_spec_json")" || return 1
	  full_name="$(get_full_name_from_user_spec_json "$user_spec_json")" || return 1
	  uid="$(get_uid_from_user_spec_json "$user_spec_json")" || return 1
	  user_class="$(get_user_class_from_user_spec_json "$user_spec_json")" || return 1
	  avatar="$(get_avatar_subpath_from_user_spec_json "$user_spec_json")" || return 1
	
	  if does_user_exist "$short_name"; then
	    report_warning "User ($short_name) already exists; skipping creation of this user."
	    continue
	  fi
	
	  report "Need to create user: $short_name ($full_name), uid=$uid, class=$user_class, avatar=$avatar"

	  create_local_user_account
	  
	done < <(jq -c '.users_to_create[]' <<<"$users_to_create_json")
  
  report_end_phase_standard
}

function create_local_user_account() {
  local name="$1"
  local uid="$2"
  local user_class="$3"
  local avatar_rel="$4"

  local vol="${VOC_VOL[$vocation]:-}"
  [[ -n "$vol" ]] || { report "ERROR: user-class '$user_class' has no mapped volume"; exit 1; }

  local pass="${VOL_PASS[$vol]:-}"
  [[ -n "$pass" ]] || { report "ERROR: volume '$vol' has no passphrase provided"; exit 1; }

  local shortname="$name"
  local home="/Volumes/${vol}/Users/${name}"

  # Strict guards (initialize-only)
  if id -u "$shortname" >/dev/null 2>&1; then
    report "ERROR: user '$shortname' already exists; refusing to modify on pristine init"
    exit 1
  fi
  
  if dscacheutil -q user | awk -v target="$uid" '$1=="uid:" && $2==target {found=1} END{exit(found?0:1)}'; then
    report "ERROR: UID '$uid' is already in use; refusing to proceed"
    exit 1
  fi

  report_action_taken "Creating user '$name' (uid=$uid, vocation=$vocation, volume=$vol)"

  run "mkdir -p '$home'"; success_or_not

  # Resolve avatar path relative to GENOMAC_USER_LOGIN_PICTURES_DIRECTORY (optional)
  local avatar_abs=""
  local picture_flag=""
  if [[ -n "${avatar_rel}" ]]; then
    avatar_abs="${GENOMAC_USER_LOGIN_PICTURES_DIRECTORY%/}/${avatar_rel}"
    if [[ -f "$avatar_abs" ]]; then
      picture_flag="-picture \"$avatar_abs\""
    else
      report "  - Avatar file not found at '$avatar_abs'; user will have the default picture"
    fi
  else
    report "  - No avatar filename provided; user will have the default picture"
  fi

  # Create user with UID, home, shell, picture; feed password via stdin (kept off argv)
  # Note: many systems accept `-password -` to read from stdin; we keep that pattern.
  local add_cmd="printf %s \"\${pass}\" | sysadminctl -addUser \"$shortname\" \
    -fullName \"$name\" \
    -UID \"$uid\" \
    -home \"$home\" \
    ${picture_flag} \
    -password -"
  run "$add_cmd"; success_or_not

  # Ensure ownership of the home directory
  run "chown -R '$shortname':staff '$home'"; success_or_not
}

function get_user_spawn_config_associative_arrays() {
  # Get values for associative arrays volume_name_from_user_class and
  # onepassword_key_from_user_class

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

	if ! populate_associative_array_from_json_object \
		"$json_input" \
		'.volume_name_from_user_class' \
		volume_name_from_user_class
	then
		report_fail "Failed to populate volume_name_from_user_class."
		return 1
	fi

	if ! populate_associative_array_from_json_object \
		"$json_input" \
		'.onepassword_key_from_user_class' \
		onepassword_key_from_user_class
	then
		report_fail "Failed to populate onepassword_key_from_user_class."
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
#  	report_end_phase_standard
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
