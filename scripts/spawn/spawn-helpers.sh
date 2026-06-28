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

  print -r -- "${(j:, :)short_names}"
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
  
  print -r -- "$path_of_parent_of_home_directories"
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

function get_users_to_create_from_GenoMac_private() {
  # Get users_to_create JSON object from GenoMac-private/spawn/specs-of-users-to-create.json

  report_start_phase_standard
  local github_pat
  local users_to_create_json

  github_pat="$(get_GitHub_PAT_for_GenoMac_private_from_1Password_vault)"
    
  if ! users_to_create_json="$(
    read_github_repo_file_raw \
      --private \
      --pat "$github_pat" \
      "$GENOMAC_COMMON_OWNER" \
      "$GENOMAC_PRIVATE_REPO_NAME" \
      "$GENOMAC_PRIVATE_SPAWN_COMMIT_ID" \
      "$GENOMAC_PRIVATE_PATH_OF_SPECS_OF_USERS_TO_CREATE"
      )"; then
    report_fail "Failed to read specifications of the users to create from GenoMac-private."
    return 1
  fi

  report_end_phase_standard
  print -r -- "$users_to_create_json"
}

function get_user_spawn_config_from_GenoMac_private() {
  # Get JSON contents of GenoMac-private/spawn/user-spawn-config.json

  report_start_phase_standard
  local github_pat
  local user_spawn_config_json

  github_pat="$(get_GitHub_PAT_for_GenoMac_private_from_1Password_vault)"

  # read_github_repo_file_raw is defined in GitHub-shared/scripts/helpers-git.sh
  if ! user_spawn_config_json="$(
    read_github_repo_file_raw \
      --private \
      --pat "$github_pat" \
      "$GENOMAC_COMMON_OWNER" \
      "$GENOMAC_PRIVATE_REPO_NAME" \
      "$GENOMAC_PRIVATE_SPAWN_COMMIT_ID" \
      "$GENOMAC_PRIVATE_PATH_OF_USER_SPAWN_CONFIG"
      )"; then
    report_fail "Failed to read user spawn config from GenoMac-private."
    return 1
  fi

  report_end_phase_standard
  print -r -- "$user_spawn_config_json"
}

function populate_user_spawn_associative_arrays_from_json() {
  # Populates from supplied user_spawn_config_json the three associative arrays:
  # volume_name_from_user_class, onepassword_key_from_user_class, and
  # user_attributes_from_user_class.
  #
  # NOTES:
  # - volume_name_from_user_class and onepassword_key_from_user_class are JSON
  #   objects, the propery value of each is a scalar
  # - user_attributes_from_user_class have each value an array of strings
  #
  # Usage:
  #   populate_user_spawn_associative_arrays_from_json <<<"$user_spawn_config_json"
  
  report_start_phase_standard

  local json_input
  json_input="$(cat)"

  # NOTE: populate_associative_array_from_json_object_of_scalars() and
  #       populate_associative_array_from_json_object_of_string_arrays()
  #       are defined in GenoMac-shared/scripts/helpers-json.sh

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

function get_GitHub_PAT_for_GenoMac_private_from_1Password_vault() {
  # Prints to stdout the GitHub PAT for the GenoMac-private repo, retrieved from 1Password.
  #
  # vault: OP_VAULT_FOR_GENOMAC_PRIVATE_GITHUB_PAT
  # item:  OP_ITEM_NAME_GENOMAC_PRIVATE_GITHUB_PAT
  # field: token

  report_start_phase_standard

  local github_pat

  if ! whence -w read_1password_item_token >/dev/null 2>&1; then
    report_fail "PROGRAMMER_ERROR: Missing required function or command: read_1password_item_token"
    return 1
  fi

  if ! github_pat="$(read_1password_item_token "$OP_VAULT_FOR_GENOMAC_PRIVATE_GITHUB_PAT" "$OP_ITEM_NAME_GENOMAC_PRIVATE_GITHUB_PAT")"; then
    report_fail "Failed to retrieve GitHub PAT for GenoMac-private from 1Password."
    return 1
  fi

  if [[ -z "$github_pat" ]]; then
    report_fail "Retrieved empty GitHub PAT for GenoMac-private from 1Password."
    return 1
  fi

  print -r -- "$github_pat"
  report_end_phase_standard
}

############### Below this line, the code is DEPRECATED

# function get_users_to_create_from_1password() {
#   report_start_phase_standard
#   local users_to_create_json
# 
#   if ! users_to_create_json="$(
#     read_1password_item_notes_plain "$OP_VAULT_FOR_GENOMAC_USER_CREATION" "$OP_ITEM_NAME_SPECS_OF_USERS_TO_CREATE"
#     )"; then
#     report_fail "Failed to read users-to-create JSON from 1Password."
#     return 1
#   fi
# 
#   report_end_phase_standard
#   print -r -- "$users_to_create_json"
# }

# function get_user_spawn_config_from_1password() {
#   # Get plain-text item $OP_ITEM_NAME_USER_SPAWN_CONFIG from 1Password vault
#   # $OP_VAULT_FOR_GENOMAC_USER_CREATION
#   #
#   # Hint: OP_VAULT_FOR_GENOMAC_USER_CREATION
#   # Hint: OP_ITEM_NAME_USER_SPAWN_CONFIG="user-spawn-config"
# 
#   report_start_phase_standard
#   local user_spawn_config_json
# 
#   if ! user_spawn_config_json="$(
#     read_1password_item_notes_plain "$OP_VAULT_FOR_GENOMAC_USER_CREATION" "$OP_ITEM_NAME_USER_SPAWN_CONFIG"
#   )"; then
#     report_fail "Failed to read user spawn config from 1Password."
#     return 1
#   fi
# 
#   report_end_phase_standard
#   print -r -- "$user_spawn_config_json"
# }
