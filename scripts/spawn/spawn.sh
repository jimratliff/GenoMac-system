#!/usr/bin/env zsh

set -euo pipefail

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
  # A separate configuration file maps "user-class" to both (a) a password and (b) a volume.
  #   {
  #     "volumes": {
  #       "Volume1": {
  #         "container_key": "primary_user_container"
  #       },
  #       "Volume2": {
  #         "container_key": "primary_user_container"
  #       },
  #       "Volume3": {
  #         "container_key": "isolated_container"
  #       }
  #     },
  #     "user_class_to_volume": {
  #       "simple_admin": "Volume1",
  #       "personal": "Volume2",
  #       "work": "Volume3"
  #     }
  #   }  
  #
  # This function assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  # - The following environment variables have been defined:
  #   - 1PASSWORD_VAULT_FOR_GENOMAC_STUFF
  #   - USER_DIRECTORY_CONTAINER_WITHIN_VOLUME
  
  report_start_phase_standard
  print_banner_text "BEGIN USER CREATION"
  report_action_taken "Beginning process to create users"

  keep_sudo_alive
  
  prompt_configurer_to_supply_login_pictures_if_desired

  get_mappings_from_user_class_to_passwords_and_volumes

  get_list_of_user_specs_to_create

  

  

  

  # ############### TODO WORK IN PROGRESS

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

function get_mappings_from_user_class_to_passwords_and_volumes() {
  # ############### TODO WORK IN PROGRESS


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

  report_end_phase_standard
}
