#!/usr/bin/env zsh

function does_user_name_exist() {
  # Returns success (exit status 0) iff user with the given short name $1 exists;
  # otherwise returns exit status 1.
  
  report_start_phase_standard
  local user_name_to_test="$1"

  if id -u "$user_name_to_test" >/dev/null 2>&1; then
	# User name exists
    report_end_phase_standard
    return 0
  fi

  # User name does not exist
  report_end_phase_standard
  return 1
}

function does_user_uid_exist() {
  # Returns success (exit status 0) iff a user with the given UID $1 exists;
  # otherwise returns exit status 1.

  report_start_phase_standard
  local uid_to_test="${1:?missing uid}"

  local users_with_uid_to_test
  # Ask Directory Services for user records under /Users whose UniqueID attribute
  # equals $uid_to_test, and store any matching output
  users_with_uid_to_test="$(dscl . -search /Users UniqueID "$uid_to_test" 2>/dev/null)"

  if [[ -n "$users_with_uid_to_test" ]]; then
    # UID exists
    report_end_phase_standard
    return 0
  fi

  # UID does not exist
  report_end_phase_standard
  return 1
}

function string_of_short_names_with_uid() {
  # Prints a comma-separated string to stdout of short names whose UniqueID equals $1.

  local uid_to_test="${1:?missing uid}"
  local -a short_names

  short_names=("${(@f)$(
    dscl . -search /Users UniqueID "$uid_to_test" 2>/dev/null \
      | awk '{print $1}'
  )}")

  print -- "${(j:, :)short_names}"
}

function confirm_secure_token_was_enabled_for_user() {
  # Normal exit (exit status 0) implies that Secure Token is enabled for user with short name $1
  # Otherwise, either the check for Secure Token status failed or gave a result not
  # expected when Secure Token is enabled.
  
  report_start_phase_standard
  local short_name="$1"
  local output

  if ! output="$(sysadminctl -secureTokenStatus "$short_name" 2>&1)"; then
    report_fail "Failed to determine Secure Token status for user ${short_name}."
    return 1
  fi

  if [[ "$output" == *"Secure token is ENABLED for user"* ]]; then
    report_success "Secure Token is enabled for user ${short_name}."
    report_end_phase_standard
    return 0
  fi

  report_fail "Secure Token does not appear to be enabled for user ${short_name}. Output was: ${output}"
  return 1
}

function parent_of_users_home_directories() {
  # Constructs the path of the parent of users’ home directories given the volume name
  # 
  # The one argument must be either
  # - the volume name, if the volume is *not* the startup volume, 
  #   - resulting in "/Volumes/volume_name/Users"
  # - '::startup_volume::' (environment variable: STARTUP_VOLUME_SIGNIFIER) if the volume *is* the startup volume
  #   - resulting in "/Users"
  # using the environment variable DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES.
  # HINT: DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES="/Users" (note that it *includes* the leading `/`)

  local volume_name="$1"
  local path_of_parent_of_home_directories

  if volume_name_is_startup_volume_signifier "$volume_name" ; then
    path_of_parent_of_home_directories="${DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES}"
  else
    path_of_parent_of_home_directories="/Volumes/${volume_name}${DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES}"
  fi
  
  print -- "$path_of_parent_of_home_directories"
}

function get_array_of_users_to_be_initially_configured() {
  # Return array of newly created users who haven’t yet been initially configured by GenoMac-user.
  #
  # See GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh »
  #    				construct_system_state_string_for_user_in_need_of_initial_config()
  # for the format of the relevant state strings.
  
  report_start_phase_standard
  local short_name
  local state_string
  local state_string_prefix

  local -a state_strings
  local -a user_short_names=()

  # Collect state strings, one for each user awaiting initial configuration
  state_string_prefix="$(construct_system_state_string_for_user_in_need_of_initial_config --prefix-only)"
  _state_strings_with_prefix "${state_string_prefix}" "system"
  state_strings=("${reply[@]}")

  # Construct array of user short-names that are awaiting initial configuration

  for state_string in "${state_strings[@]}"; do
    short_name="$(
	    nonempty_content_between_delimiters \
	      "$state_string" \
        "$GENOMAC_STATE_STRING_DELIMITER_A" \
        "$GENOMAC_STATE_STRING_DELIMITER_B"
    )"
	  user_short_names+=("$short_name")
  done
  reply=("${user_short_names[@]}")
  
  report_end_phase_standard
}

function display_users_to_be_initially_configured() {
  # Prints list of users still awaiting initial configuration.
  
  report_start_phase_standard
  
  local number_of_awaiting_users
  local report_string=""
  local user_short_name

  local -a user_short_names
  
  get_array_of_users_to_be_initially_configured
  user_short_names=("${reply[@]}")

  number_of_awaiting_users=${#user_short_names[@]}

  if (( ! number_of_awaiting_users )); then
    report "There are no users awaiting their initial configuration by GenoMac-user."
  else
    report_string="📋 The following $number_of_awaiting_users user(s) is/are awaiting their initial configuration by GenoMac-user:${NEWLINE}"
    for user_short_name in "${user_short_names[@]}"; do
      report_string+="${user_short_name}${NEWLINE}"
    done
    report_highlight "$report_string"
  fi
  
  report_end_phase_standard
}

function get_short_name_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.short_name' <<<"$user_spec_json"
}

function get_full_name_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.full_name' <<<"$user_spec_json"
}

function get_uid_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.uid' <<<"$user_spec_json"
}

function get_user_class_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.user_class' <<<"$user_spec_json"
}

function get_avatar_subpath_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.avatar // empty' <<<"$user_spec_json"
}

function print_attributes_from_user_spec_json() {
  local user_spec_json="${1:?missing user_spec_json}"

  jq -r '
    (.attributes // [])
    | .[]
    | if type == "string" then .
      else error("user attribute is not a string")
      end
  ' <<<"$user_spec_json"
}


