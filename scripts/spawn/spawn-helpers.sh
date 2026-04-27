#!/usr/bin/env zsh

function sysadminctl_adduser() {
	# An interface to the addUser subcommand of sysadminctl.
	#
	# Creates a new user and, by default, awards the new user a Secure Token.
	# 
	# Intended usage is to provide the password for each of (a) the new user and (b) an existing admin user
	# with a Secure Token by providing the name of a 1Password vault and the name of the items in that vault
	# that contain those two passwords. (Alternatively, but insecurely, cleartext passwords can be supplied
	# primarily for testing purposes.)
	#
	# Parameters (optional unless otherwise specified):
	#   --shortname						mandatory	<string> of user’s short name
	#		--fullname								<string> of user’s full name
	#		--uid						mandatory	<integer> of user’s ID
	#   --avatar-path								<string> of full path to avatar file
	#
	#   Home-directory parameters
	#		--container					mandatory	<string> of container that contains --volume
	#		--volume					mandatory	<string> of volume to house user’s home directory
	#
	#   --admin-user-name				mandatory	<string> of short name of existing admin user with Secure Token
	#
	#   PASSWORD SPECIFICATIONS: Mandatory to specify *either* (a) 1Password vault and items or (b) cleartext passwords
	#     1PASSWORD:
	#   --op-vault									<string> of 1Password vault name containing items with desired passwords
	#   --op-item-user-password						<string> naming the 1Password item with password for --shortname
	#   --op-item-admin-password				 	<string> naming the 1Password item with password for --admin-user-name
	#
	#	  CLEARTEXT (insecure, meant only for testing):
	#   --cleartext-password-user					cleartext <string> of password for --shortname
	#   --cleartext-password-admin					cleartext <string> of password for --admin-user-name
	#
	#   --hint										<string> of password hint
	#
	#   --not-an-admin								If supplied, new user will *not* be an admin user. 
	#												When not supplied (default), new user *will* be an admin user.
	#   --no-secure-token							If supplied, do *not* give new user a Secure Token. 
	#												When not supplied (default), new user *does* receive a Secure Token.
	
	
	report_start_phase_standard

	report_end_phase_standard
}

function does_user_exist() {
  # Returns success iff a user with the given short name exists.
  report_start_phase_standard

  local user_name_to_test="$1"

  if id -u "$user_name_to_test" >/dev/null 2>&1; then
	  report_warning "User $user_name_to_test already exists. Moving on…"
    report_end_phase_standard
    return 0
  fi

  report_end_phase_standard
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

