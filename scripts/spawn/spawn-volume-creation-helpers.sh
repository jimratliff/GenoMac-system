#!/usr/bin/env zsh

function record_volume_and_1Password_item_key(){
  # Takes the volume and 1Password item key for a new user and appropriately record
  # whether this volume needs to be created.
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  
  report_end_phase_standard
}

function test_volume_as_already_complete(){
  # Template for a Zsh function in Project GenoMac
  report_start_phase_standard
  report_end_phase_standard
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
