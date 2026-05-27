#!/usr/bin/env zsh

function conditionally_mark_volume_as_pending_creation(){
  # Set system-scoped state to indicate that a volume needs to be created and encrypted
  # with a particular passphrase
  #
  # Parameters:
  # - $1: volume name
  # - $2: name of 1Password item key.
  #
  # Intended to be called after a new user, with home directory on the volume, is
  # created.
  #
  # Takes no action if volume_name is STARTUP_VOLUME_SIGNIFIER (i.e., "::startup_volume::"),
  # because the startup volume necessarily already exists.
  #
  # This operation is idempotent if a non-startup volume has already been marked as
  # pending creation with the same passphrase.
  #
  # If marked as pending twice, but with different passphrases, this will result in two
  # states for the same volume but with different passphrases. This isn’t caught at this
  # stage; instead, it’s caught when the list of pending volumes is reviewed.
  
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  local state_string="$GMS_STATE_VOLUME_IS_PENDING_PREFIX"

  if "$volume_name" == "$STARTUP_VOLUME_SIGNIFIER"; then
    report "The “volume name” “$volume_name” signifies the startup volume, which necessarily exists.${NEWLINE}Nothing further to record."
    report_end_phase_standard
    return 0
  fi

  report_action_taken "Set state to mark that volume “${volume_name}” needs to be created and encrypted using 1Password item key “${op_item_key}”."
  state_string=$(construct_state_string_for_volume_1password_key_pending_creation "$volume_name" "$op_item_key")
  set_genomac_system_state "$state_string"

  report_end_phase_standard
  return 0
}

function conditionally_mark_volume_as_pending_creation_DEPRECATED(){
  # Takes the volume and 1Password item key for a new user and, when appropriate, marks
  # in a system state that this volume needs to be created with the indicated passphrase.
  #
  # Parameters:
  # - $1: volume name
  # - $2: name of 1Password item key
  #
  # Takes no action if any of:
  # - volume_name is STARTUP_VOLUME_SIGNIFIER="::startup_volume::"
  # - volume_name is already marked as having been created
  # - volume_name is already marked as pending
  # - volume_name is mounted
  #
  # Otherwise sets system state with prefix GMS_STATE_VOLUME_IS_PENDING_PREFIX for this volume.
  
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  local state_string

  if "$volume_name" == "$STARTUP_VOLUME_SIGNIFIER"; then
    report "The “volume name” “$volume_name” signifies the startup volume, which necessarily exists.${NEWLINE}Nothing further to record."
    report_end_phase_standard
    return 0
  fi

  if volume_name_is_mounted "$volume_name"; then
    report "The volume “$volume_name” is currently mounted. Nothing further to record."
    report_warning "Although volume “$volume_name” is currently mounted, I can’t guarantee its passphrase."
    report_end_phase_standard
    return 0
  fi

  if test_whether_volume_is_marked_created "$volume_name" "$op_item_key"; then
    report "The volume “$volume_name” has been marked created. Nothing further to record."
    report_end_phase_standard
    return 0
  fi
  report "Volume “$volume_name” hasn’t been recorded as having been created"

  if test_whether_volume_is_marked_pending "$volume_name" "$op_item_key"; then
    report "The volume “$volume_name” is already marked as pending. Nothing further to record."
    report_end_phase_standard
    return 0
  fi
  report "Volume “$volume_name” hasn’t been recorded as being pending."

  report_action_taken "Set state to mark that volume “${volume_name}” needs to be created and encrypted using 1Password item key “${op_item_key}”."
  state_string=$(construct_state_string_for_volume_1password_key_pending_creation "$volume_name" "$op_item_key")
  set_genomac_system_state "$state_string"

  report_end_phase_standard
  return 0
}

#  function test_whether_volume_is_marked_created(){
#    # Tests whether state exist asserting the given volume has already been created.
#    local volume_name="${1:?missing/empty volume_name}"
#    local op_item_key="${2:?missing/empty op_item_key}"
#    local result
#    test_volume_1Password_key_state_was_found_without_mismatch "$volume_name" "$op_item_key" "$GMS_STATE_VOLUME_IS_CREATED_PREFIX"
#    result=$?
#    report_end_phase_standard
#    return "$result"
#  }

function test_whether_volume_is_marked_pending(){
  # Tests whether state exists asserting the given volume has been noted as pending (needing creation).
  local volume_name="${1:?missing/empty volume_name}"
  local op_item_key="${2:?missing/empty op_item_key}"
  local result
  test_volume_1Password_key_state_was_found_without_mismatch "$volume_name" "$op_item_key" "$GMS_STATE_VOLUME_IS_PENDING_PREFIX"
  result=$?
  report_end_phase_standard
  return "$result"
}

function test_volume_1Password_key_state_was_found_without_mismatch(){
  # Tests whether exactly one volume-creation-is-pending state exists for the desired volume.
  # If so, crashes if the existing 1Password key doesn’t match the desired 1Password key supplied.
  #
  # Parameters:
  #   $1: volume name
  #   $2: 1Password item key for the desired passphrase for this volume
  #
  # Returns:
  #   0 if exactly one matching state exists and its 1Password key matches the desired key
  #     (If the 1Password key of the existing state is different, exits/bombs)
  #   1 if no state matches the volume/prefix
  #
  #   Exits/bombs with exit code 70 if:
  #   - multiple matching states exist
  #       Multiple matching states implies that the same volume is assigned multiple
  #       1Password item keys, which is a conflict, because a volume can have only a
  #       single encryption passphrase.
  #   - one state matches the volume/prefix, but its 1Password key is different from the
  #     supplied as the desired 1Password key

  report_start_phase_standard

  local volume_name="${1:?missing/empty volume_name}"
  local op_item_key="${2:?missing/empty op_item_key}"
  local state_string_prefix="$GMS_STATE_VOLUME_IS_PENDING_PREFIX"
  local volume_search_prefix
  local desired_state_string
  local failure_message
  local matching_state_string
  local -a matching_state_strings

  volume_search_prefix="$(construct_state_string_for_volume_1password_key_pending_creation --volume-only "${volume_name}")"

  # Collects all state strings for this volume (with $state_string_prefix)
  _state_strings_with_prefix "$volume_search_prefix" "$GENOMAC_SCOPE_SYSTEM" || exit 70
  matching_state_strings=("${reply[@]}")

  case "${#matching_state_strings[@]}" in
    0)
      # No existing state for this volume (with $state_string_prefix)
      report_end_phase_standard
      return 1
      ;;
  
    1)
      # Exactly one existing state for this volume (with $state_string_prefix)
      # Test that the 1Password key of the existing state matches the desired key
      desired_state_string="$(construct_state_string_for_volume_1password_key_pending_creation "${volume_name}" "${op_item_key}")"
      if [[ "${matching_state_strings[1]}" == "${desired_state_string}" ]]; then
        report_end_phase_standard
        return 0
      fi
      report_fail \
        "State exists for volume “${volume_name}”, but with mismatched 1Password item key.${NEWLINE}"\
        "Expected state string: ${desired_state_string}${NEWLINE}"\
        "Found state string: ${matching_state_strings[1]}"
      exit 70
      ;;
  
    *)
      # Two or more existing states for this volume (with $state_string_prefix)
      # This implies more than one encryption passphrase for the volume, which is a conflict.
      failure_message="Multiple states found for prefix: ${state_string_prefix_with_volume_name}${NEWLINE}"
      failure_message+="Matching state strings:"
      for matching_state_string in "${matching_state_strings[@]}"; do
        failure_message+="${NEWLINE}  ${matching_state_string}"
      done
      report_fail "$failure_message"
      exit 70
      ;;
  esac
}

function construct_state_string_for_volume_1password_key_pending_creation(){
  # Constructs a state string that encodes (a) volume name and (b) 1Password item key.
  #
  # Positional arguments:
  #   $1: volume_name
  #   $2: op_item_key
  #
  # Without --volume-only:
  #   Requires exactly:
  #     volume_name op_item_key
  #
  # With --volume-only:
  #   Requires:
  #     volume_name
  #
  #   Allows, but ignores:
  #     op_item_key
  #
  # In the default form (i.e., without --volume-only), constructs a state string of the form:
  #   VOLUME_CREATION_IS_PENDING∞§¶some_volume¶§∞PERSONAL_PASSWORD§∞¶
  #   where:
  #     'some_volume' is the name of a volume
  #     'PERSONAL_PASSWORD' is a 1Password item key
  #
  # With --volume-only, constructs a truncated version where the trailing 
  # 1Password item key is omitted, e.g.,
  #   VOLUME_CREATION_IS_PENDING∞§¶some_volume¶§∞
  # This can be used as a prefix to search for all states for the given volume
  # without regard to the 1Password item key.
  # 
  # (That trailing GENOMAC_STATE_STRING_DELIMITER_B in the --volume-only case is intentional.
  # It allows exact-prefix searching for all states for a given volume without also matching 
  # similarly named volumes, e.g. "volume_1" should not match "volume_11".)
  #
  # Delimiters:
  #   '∞§¶' (environment variable GENOMAC_STATE_STRING_DELIMITER_A) is between the state_string_prefix and volume name.
  #   '¶§∞' (environment variable GENOMAC_STATE_STRING_DELIMITER_B) is between the volume name and 1Password item key.
  #   '§∞¶' (environment variable GENOMAC_STATE_STRING_DELIMITER_C) comes after 1Password item key.
  #
  # Neither (a) the volume name nor (b) the 1Password item key may contain either GENOMAC_STATE_STRING_DELIMITER_A,
  # GENOMAC_STATE_STRING_DELIMITER_B, or GENOMAC_STATE_STRING_DELIMITER_C.
  #
  # Usage forms:
  #   construct_state_string_for_volume_1password_key_pending_creation volume_name op_item_key
  #   construct_state_string_for_volume_1password_key_pending_creation --volume-only volume_name [op_item_key]
  #
  # The --volume-only switch may appear anywhere before a literal --.
  
  report_start_phase_standard

  local wants_volume_only=false
  local -a positional_args=()

  while (( $# )); do
    case "$1" in
      --volume-only)
        wants_volume_only=true
        shift
        ;;

      --)
        shift
        positional_args+=("$@")
        break
        ;;

      --*)
        report_fail "Unknown option: $1"
        return 64
        ;;

      *)
        positional_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$wants_volume_only" == true ]]; then
    if (( ${#positional_args[@]} < 1 )); then
      report_fail "Too few arguments with --volume-only: expected volume_name [op_item_key]"
      return 64
    fi

    if (( ${#positional_args[@]} > 2 )); then
      report_fail "Too many arguments with --volume-only: expected volume_name [op_item_key]"
      return 64
    fi
  else
    if (( ${#positional_args[@]} != 2 )); then
      report_fail "Expected 2 arguments: volume_name op_item_key"
      return 64
    fi
  fi

  # local state_string_prefix="${positional_args[1]:?missing/empty state_string_prefix}"
  local volume_name="${positional_args[1]:?missing/empty volume_name}"
  local op_item_key=""

  local state_string_prefix="${GMS_STATE_VOLUME_IS_PENDING_PREFIX}"

  if ! [[ "$wants_volume_only" == true ]]; then
    op_item_key="${positional_args[2]:?missing/empty op_item_key}"
  fi

  local state_string
  state_string="${state_string_prefix}${GENOMAC_STATE_STRING_DELIMITER_A}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_B}"

  if ! [[ "$wants_volume_only" == true ]]; then
    # Appends 1Password item key to previously computed volume-only state string
    state_string="${state_string}${op_item_key}${GENOMAC_STATE_STRING_DELIMITER_C}"
  fi

  print -- "$state_string"

  report_end_phase_standard
}

function volume_name_is_mounted() {
  # Tests whether a non-startup volume with the given volume name is currently mounted.
  #
  # Returns:
  #   0 if mounted at /Volumes/$volume_name
  #   1 otherwise
  #
  # Does not handle the startup volume, which is normally mounted at /, and which must be
  # mounted in order to run any script.
  #
  # Usage:
  #   if volume_name_is_mounted "Personal"; then
  #     print "Personal is mounted"
  #   else
  #     print "Personal is not mounted"
  #   fi
  
  report_start_phase_standard

  local volume_name="${1:?missing/empty volume_name}"
  local mount_point="/Volumes/${volume_name}"

  [[ -d "${mount_point}" ]] || return 1
  mount | grep -Fq " on ${mount_point} "
  report_end_phase_standard
}

