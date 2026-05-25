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
  # Constructs the path of the parent of users’ home directories.
  # Takes either:
  #   --startup-volume
  #     resulting in "/Users"
  #   --volume-name <volume_name>
  #     resulting in "/Volumes/volume_name/Users"
  # using the environment variable DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES.
  # NOTE: The environment variable DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES
  #       is assumed to *include* the leading `/`.
  # HINT: DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES="/Users"
  
  local is_startup_volume=false
  local is_not_startup_volume=false
  local volume_name=""
  local path_of_parent_of_home_directories

  while (( $# > 0 )); do
    case "$1" in
      --startup-volume)
        is_startup_volume=true
        shift
        ;;
      --volume-name)
        is_not_startup_volume=true
        volume_name=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;
      *)
        report_fail "Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  if [[ "$is_startup_volume" == true && "$is_not_startup_volume" == true ]]; then
    report_fail "Specify EITHER --startup-volume or --volume-name, but NOT both."
    return 1
  fi

  if [[ "$is_startup_volume" != true && "$is_not_startup_volume" != true ]]; then
    report_fail "You must specify EITHER --startup-volume or --volume-name.${NEWLINE}is_startup_volume: ${is_startup_volume} is_not_startup_volume: ${is_not_startup_volume}."
    return 1
  fi

  if [[ "$is_startup_volume" == true ]]; then
    path_of_parent_of_home_directories="${DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES}"
  else
    path_of_parent_of_home_directories="/Volumes/${volume_name}${DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES}"
  fi
  
  print -- "$path_of_parent_of_home_directories"
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

############### Warning: DEPRECATED
# determine_startup_container() is DEPRECATED because irrelevant

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

  # Normalize to form diskutil apfs addVolume accepts comfortably.
  # If the plist already includes /dev/, leave it alone.
  container_ref="/dev/${container_ref#/dev/}"

  report "Container of startup volume is: ${container_ref}"

  # “Return” value
  print -- "$container_ref"

  report_end_phase_standard
}


