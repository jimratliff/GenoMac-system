#!/usr/bin/env zsh

set -euo pipefail

# Global associative arrays to be populated from item ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
# of 1Password vault ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
typeset -gA volume_key_from_user_class
typeset -gA op_key_for_passphrase_from_volume_key
typeset -gA volume_name_from_volume_key

function create_user_accounts_for_this_Mac() {
  # Creates specific user accounts for this Mac.
  # When a user to be created is specified to reside (i.e., its home directory inhabits) a volume
  #   that doesn’t currently exist, that APFS volume is created.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which user already exists, as does
  #   a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  #   users.
  #
  # Each user to be created is specified by:
  # - "name"
  #   - a string, e.g., "Betty")
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
  # To be clear, "user-class" specifies the *volume* of the home directory but the actually path to the home directory
  # is `some_volume/Users/some_user`.
  # See environment variable: USER_DIRECTORY_CONTAINER_WITHIN_VOLUME="Users"
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
  #     "1password_key_for_passphrase_from_volume_key": {
  #       "startup_volume": "THE_STARTUP_PASSWORD",
  #       "personal_volume": "PERSONAL_PASSWORD",
  #       "work_volume": "WORK_PASSWORD",
  #       "auxiliary_volume": "AUX_PASSWORD"
  #     }
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
  #   - USER_DIRECTORY_CONTAINER_WITHIN_VOLUME
  
  report_start_phase_standard
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  keep_sudo_alive
  
  prompt_configurer_to_supply_login_pictures_if_desired
  get_user_spawn_config_associcative_arrays
  get_list_of_user_specs_to_create
  startup_container="$(determine_startup_container)"

  # ############### TODO WORK IN PROGRESS

  report_end_phase_standard
}



function get_user_spawn_config_associcative_arrays() {
  # Get values for associative arrays volume_key_from_user_class,
  # op_key_for_passphrase_from_volume_key, and volume_name_from_volume_key

  report_start_phase_standard
  local user_spawn_config_json

  if ! user_spawn_config_json="$(get_user_spawn_config_from_1password)"; then
    report_fail "Failed to retrieve user spawn config from 1Password."
    return 1
  fi

  if ! populate_user_spawn_associative_arrays_from_json <<<"$user_spawn_config_json"; then
    report_fail "Failed to populate user spawn associative arrays from JSON."
    return 1
  fi

  report_end_phase_standard
}

get_user_spawn_config_from_1password() {

	report_start_phase_standard
	local user_spawn_config_json

	if ! user_spawn_config_json="$(
		op read "op://$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION/$ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG"
	)"; then
		report_fail "Failed to read user spawn config from 1Password."
		return 1
	fi

	report_end_phase_standard
	print -- "$user_spawn_config_json"
}

function does_user_exist() {
  report_start_phase_standard
  user_name_to_test="$1"
  # ############### TODO WORK IN PROGRESS

  report_end_phase_standard
}

function determine_startup_container() {
  # Determines the container of the startup volume.
  # This container will be used for all subsequent new volumes for user home directories
  report_start_phase_standard

  local container_ref

  if ! container_ref="$(
    "$PLISTBUDDY_PATH" -c 'Print :APFSContainerReference' /dev/stdin \
        <<<"$(diskutil info -plist /)"
  )"; then
    report_fail "Failed to determine APFS container for startup volume."
    return 1
  fi

  if [[ -z "$container_ref" ]]; then
    report_fail "APFS container reference for startup volume was empty."
    return 1
  fi

  # Normalize to form diskutil apfs addVolume accepts comfortably.
  # If the plist already includes /dev/, leave it alone.
  container_ref="/dev/${container_ref#/dev/}"

  report "Container of startup volume is: ${container_ref}"

  # “Return” value
  print -- "$container_ref"

  report_end_phase_standard
}

function prompt_configurer_to_supply_login_pictures_if_desired() {
  # Asks USER_CONFIGURER whether login pictures are desired when creating user accounts. If so, prompts USER_CONFIGURER
  # to confirm that the desired login pictures reside in GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY
  # If login pictures are desired, but their existence isn’t confirmed by USER_CONFIGURER, the user-creation process is
  # aborted.
  
  report_start_phase_standard

  if ! get_yes_no_answer_to_question "Do you want the new users to be specified with login pictures?"; then
    report "I won’t create a directory for login pictures, since you don’t want to use them"
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
