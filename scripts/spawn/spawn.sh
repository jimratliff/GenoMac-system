#!/usr/bin/env zsh

set -euo pipefail

safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-helpers.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-addUser.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-create-volume.sh"
safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn-interactive.sh"

# Global associative arrays to be populated from item ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
# of 1Password vault ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
typeset -gA volume_key_from_user_class
typeset -gA onepassword_key_for_passphrase_from_volume_key
typeset -gA volume_name_from_volume_key

function create_user_accounts_for_this_Mac() {
  # Creates specific user accounts for this Mac.
  # When a user to be created is specified to reside on (i.e., its home directory inhabits) a volume
  #   that doesn’t currently exist, that APFS volume is created.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which user already exists, as does
  #   a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  #   users.
  #
  # The users to be created are specified in a "users_to_create" JSON object.
  #
  # Each user to be created is specified by:
  # - "short_name"
  #   - a string, e.g., "Betty")
  # - "full_name" (optional)
  #   - a string, e.g., "Betty Rubble")
  # - "uid"
  #   - the user’s ID, in the range 510–999, which macOS uses to distinguish users (rather than by user name)
  #   - (Project GenoMac excludes IDs 501–509 here, even though they are legit user IDs, in order to prevent
  #     conflicts with preexisting users.)
  # - "user-class"
  #   - a string key, e.g., "simple_admin", "implementor", "unsullied", "personal", "work", "auxiliary"
  #   - Determines (a) the user’s password and (b) the volume on which the user’s home directory resides.
  # - "avatar" (optional)
  #   - Relative path to image file for the user’s avatar, e.g., "Betty.png"
  #   - The path is expressed relative to GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY
  #     - Hint: GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY="$HOME/.genomac-system-login-pictures-for-user-creation"
  #
  #   {
  #     "users_to_create": [
  #       {
  #         "short_name": "betty",
  #         "full_name": "Betty Rubble",
  #         "uid": 511,
  #         "user_class": "personal",
  #         "avatar": "Betty.png"
  #       },
  #       {
  #         "short_name": "wilma",
  #         "full_name": "Wilma Flintstone",
  #         "uid": 512,
  #         "user_class": "work"
  #       }
  #     ]
  #   }
  #
  # To be clear, "user-class" implies the *volume* of the home directory but the actual path to the home directory
  # is `some_volume/Users/some_user`.
  # See environment variable: DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES="Users"
  # and use home_directory_path_from_volume_name()
  #
  # A separate configuration file maps (a) "user-class" to a volume key, (b) volume key to a 1password key to securely
  # look up a passphrase, and (c) volume key to a volume name.
  #
  #   {
  #     "volume_key_from_user_class": {
  #       "simple_admin": "startup_volume",
  #       "implementor": "startup_volume",
  #       "unsullied": "startup_volume",
  #       "personal": "personal_volume",
  #       "work": "work_volume",
  #       "auxiliary": "auxiliary_volume"
  #     },
  #     "onepassword_key_for_passphrase_from_volume_key": {
  #       "startup_volume": "THE_STARTUP_PASSWORD",
  #       "personal_volume": "PERSONAL_PASSWORD",
  #       "work_volume": "WORK_PASSWORD",
  #       "auxiliary_volume": "AUX_PASSWORD"
  #     },
  #     "volume_name_from_volume_key": {
  #       "startup_volume": "Volume_for_Startup",
  #       "personal_volume": "Volume_for_Personal_Users",
  #       "work_volume": "Volume_for_Work_Users",
  #       "auxiliary_volume": "Volume_for_Auxiliary_Users"
  #     },
  #   }
  #
  # This function assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  # - The following environment variables have been defined:
  #   - ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
  #   - ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
  #   - ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE
  #   - DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES
  
  report_start_phase_standard
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  # Sign into 1Password
  op signin

  get_user_spawn_config_associative_arrays
  users_to_create_json="$(get_users_to_create_from_1password)" || return 1

  keep_sudo_alive
  
  prompt_configurer_to_supply_login_pictures_if_desired

  create_users
  

  # startup_container="$(determine_startup_container)"

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
  # Get values for associative arrays volume_key_from_user_class,
  # onepassword_key_for_passphrase_from_volume_key, and volume_name_from_volume_key

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
		'.volume_key_from_user_class' \
		volume_key_from_user_class
	then
		report_fail "Failed to populate volume_key_from_user_class."
		return 1
	fi

	if ! populate_associative_array_from_json_object \
		"$json_input" \
		'.onepassword_key_for_passphrase_from_volume_key' \
		onepassword_key_for_passphrase_from_volume_key
	then
		report_fail "Failed to populate onepassword_key_for_passphrase_from_volume_key."
		return 1
	fi

	if ! populate_associative_array_from_json_object \
		"$json_input" \
		'.volume_name_from_volume_key' \
		volume_name_from_volume_key
	then
		report_fail "Failed to populate volume_name_from_volume_key."
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

function prompt_configurer_to_supply_login_pictures_if_desired() {
  # Asks USER_CONFIGURER whether login pictures are desired when creating user accounts. If so, prompts USER_CONFIGURER
  # to confirm that the desired login pictures reside in GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY
  # If login pictures are desired, but their existence isn’t confirmed by USER_CONFIGURER, the user-creation process is
  # aborted.
  
  report_start_phase_standard

  if ! get_yes_no_answer_to_question "Do you want the new users to be specified with login pictures?"; then
    report "I won’t create a directory for login pictures, since you don’t want to use them"
	report_end_phase_standard
    return 0
  fi

  report_action_taken "Creating, if necessary, directory for users’ login pictures"
  mkdir -p "$GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY" ; success_or_not

  report "The login picture for each user must be in: $GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY"
  report_action_taken "I am opening this directory for you to inspect its contents"
  open "$GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY" ; success_or_not
  if ! get_yes_no_answer_to_question "Answer “yes” if you’re satisfied the login pics are in the folder. Answer “no” to cancel."; then
    report "You want login pictures, but you haven’t confirmed you’ve supplied them.${NEWLINE}I am aborting. Feel free to try again later."
    return 1
  fi

  report_success "You have confirmed the existence of the desired login pictures. Moving on to create new users."
  
  report_end_phase_standard
}
