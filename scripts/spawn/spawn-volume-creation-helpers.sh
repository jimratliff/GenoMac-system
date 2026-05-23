#!/usr/bin/env zsh

function _test_volume_1Password_key_state_was_found_without_mismatch(){
  # Tests whether exactly one state exists for the desired volume/1Password key.
  #
  # Returns:
  #   0 if exactly one matching state exists
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
  local -a matching_state_strings

  state_string_prefix_with_volume_name=\
"${state_string_prefix}${GENOMAC_STATE_STRING_DELIMITER_A}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_B}${op_item_key}"

  _state_strings_with_prefix "$state_string_prefix_with_volume_name" "$GENOMAC_SCOPE_SYSTEM" || return 1
  matching_state_strings=("${reply[@]}")

  case "${#matching_state_strings[@]}" in
    0)
      report_end_phase_standard
      return 1
      ;;

    1)
      report_end_phase_standard
      return 0
      ;;

    *)
      report_fail "Multiple matching states found for volume “${volume_name}” and 1Password item key “${op_item_key}”."
      printf '  %s\n' "${matching_state_strings[@]}" >&2
      exit 70
      ;;
  esac
}
