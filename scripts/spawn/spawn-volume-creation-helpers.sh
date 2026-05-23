#!/usr/bin/env zsh

function record_volume_and_1Password_item_key(){
  # Takes the volume and 1Password item key for a new user and appropriately record
  # whether this volume needs to be created.
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  local state_string

  if test_whether_volume_is_already_created "$volume_name" "$op_item_key"; then
    report "The volume “$volume_name” has already been created. Nothing further to record."
    report_end_phase_standard
    return 0
  fi

  if test_whether_volume_is_pending "$volume_name" "$op_item_key"; then
    report "The volume “$volume_name” is already pending. Nothing further to record."
    report_end_phase_standard
    return 0
  fi

  state_string=$(_construct_state_string_for_volume_1password_key "$volume_name" "$op_item_key" "$GMS_STATE_VOLUME_IS_PENDING_PREFIX")
  set_genomac_system_state "$state_string"

  report_end_phase_standard
  return 0
}

function test_whether_volume_is_already_created(){
  # Tests whether state exist asserting the given volume has already been created.
  local volume_name="${1:?missing/empty volume_name}"
  local op_item_key="${2:?missing/empty op_item_key}"
  local result
  _test_volume_1Password_key_state_was_found_without_mismatch "$volume_name" "$op_item_key" "$GMS_STATE_VOLUME_IS_CREATED_PREFIX"
  result=$?
  report_end_phase_standard
  return "$result"
}

function test_whether_volume_is_pending(){
  # Tests whether state exists asserting the given volume has been noted as pending (needing creation).
  local volume_name="${1:?missing/empty volume_name}"
  local op_item_key="${2:?missing/empty op_item_key}"
  local result
  _test_volume_1Password_key_state_was_found_without_mismatch "$volume_name" "$op_item_key" "$GMS_STATE_VOLUME_IS_PENDING_PREFIX"
  result=$?
  report_end_phase_standard
  return "$result"
}

function _test_volume_1Password_key_state_was_found_without_mismatch(){
  # Tests whether exactly one state exists for the desired volume/1Password key.
  #
  # Returns:
  #   0 if exactly one matching state exists and its 1Password key matches the desired key
  #     (If the 1Password key of the existing state is different, exits/bombs)
  #   1 if no matching state exists
  #   exits/bombs if multiple matching states exist
  #     Multiple matching states implies that the same volume is assigned multiple
  #     1Password item keys, which is a conflict, because a volume can have only a
  #     single encryption passphrase.

  report_start_phase_standard

  local volume_name="${1:?missing/empty volume_name}"
  local op_item_key="${2:?missing/empty op_item_key}"
  local state_string_prefix="${3:?missing/empty state_string_prefix}"
  local state_string_prefix_with_volume_name
  local desired_state_string
  local failure_message
  local matching_state_string
  local -a matching_state_strings

  state_string_prefix_with_volume_name="${state_string_prefix}${GENOMAC_STATE_STRING_DELIMITER_A}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_B}"

  # Collects all state strings for this volume (with $state_string_prefix)
  _state_strings_with_prefix "$state_string_prefix_with_volume_name" "$GENOMAC_SCOPE_SYSTEM" || exit 70
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
      desired_state_string="${state_string_prefix_with_volume_name}${op_item_key}"
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

function _construct_state_string_for_volume_1password_key(){
  # Constructs a state string of the form 'VOLUME_CREATION_IS_COMPLETE_∞§¶some_volume¶§∞PERSONAL_PASSWORD'
  # where:
  #   'VOLUME_CREATION_IS_COMPLETE_' could instead be 'VOLUME_CREATION_IS_PENDING_'
  #   'some_volume' is the name of a volume
  #   'PERSONAL_PASSWORD' is a 1Password item key
  #
  # - $3 is expected to be either GMS_STATE_VOLUME_IS_CREATED_PREFIX or GMS_STATE_VOLUME_IS_PENDING_PREFIX
  # - The first delimiter (between the the state_string_prefix and the volume name) is GENOMAC_STATE_STRING_DELIMITER_A
  #   - GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
  # - The second delimiter (between the volume name and the 1Password item key) is GENOMAC_STATE_STRING_DELIMITER_B
  #   - GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  local state_string_prefix="$3"
  local state_string

  state_string="${state_string_prefix}${GENOMAC_STATE_STRING_DELIMITER_A}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_B}${op_item_key}"
  print -- "$state_string"
  
  report_end_phase_standard
}

