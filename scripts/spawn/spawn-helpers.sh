#!/usr/bin/env zsh

function does_user_exist() {
  # Returns success (exit status 0) iff user with the given short name $1 exists;
  # otherwise returns exit status 1.
  
  report_start_phase_standard
  local user_name_to_test="$1"

  if id -u "$user_name_to_test" >/dev/null 2>&1; then
	report_warning "User $user_name_to_test already exists. Moving on…"
    report_end_phase_standard
    return 0
  fi

  report "User $user_name_to_test does NOT nalready exist"
  report_end_phase_standard
  return 1
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

function home_directory_path_from_volume_name() {
  # Constructs the home-directory path from the home-directory volume name (supplied as $1), using
  # the environment variable USER_DIRECTORY_CONTAINER_WITHIN_VOLUME.
  # NOTE: The environment variable USER_DIRECTORY_CONTAINER_WITHIN_VOLUME is assumed to *include* any
  #       `/` that separates the volume from a directory.
  # HINT: USER_DIRECTORY_CONTAINER_WITHIN_VOLUME="/Users"
  
  report_start_phase_standard
  local volume_name="$1"
  local home_directory_path
  
  home_directory_path="${volume_name}${USER_DIRECTORY_CONTAINER_WITHIN_VOLUME}"
  print -- "$home_directory_path"
  
  report_end_phase_standard
}

function create_encrypted_apfs_volume() {
  # Create, if not already present, an encrypted APFS volume given:
  # (a) container name ($1), (b) volume name ($2), and (c) passphrase ($3)
  
  report_start_phase_standard
  local apfs_container="$1"
  local vol_name="$2"
  local passphrase="$3"

  report_action_taken "Ensuring encrypted APFS volume '$vol_name' exists"

  if diskutil apfs list | grep -q "Name: ${vol_name} "; then
    report "  - '$vol_name' already exists; skipping creation"
	report_end_phase_standard
    return 0
  fi

  local cmd="printf %s \"\${passphrase}\" | diskutil apfs addVolume \"${apfs_container}\" APFS \"${vol_name}\" -passphrase"
  run "$cmd"; success_or_not
  report "Created encrypted APFS volume '$vol_name'"
  report_end_phase_standard
}

get_short_name_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.short_name' <<<"$user_spec_json"
}

get_full_name_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.full_name' <<<"$user_spec_json"
}

get_uid_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.uid' <<<"$user_spec_json"
}

get_user_class_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.user_class' <<<"$user_spec_json"
}

get_avatar_subpath_from_user_spec_json() {
  local user_spec_json="$1"
  jq -r '.avatar // empty' <<<"$user_spec_json"
}

