#!/usr/bin/env zsh

function mark_user_as_created(){
  # Set system-scoped state to mark user as having been created.
  # 
  # As of 5/26/2026, there’s no known use case for this system-scoped state. It’s being
  # created here because it’s easier to create at user-creation than to retrofit later.
  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="${GENOMAC_STATE_USER_EXISTS_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${user_name}${GENOMAC_STATE_STRING_DELIMITER_B}"
  set_genomac_system_state "$state_string"
  
  report_end_phase_standard
}

function set_system_states_for_user_attributes(){
  # Sets a system-scoped state for each attribute of user, whose user_spec_json is supplied as $1.
  report_start_phase_standard
  
  local user_spec_json="$1"

  short_name="$(get_short_name_from_user_spec_json "$user_spec_json")" || return 1

  local attribute_name
  while IFS= read -r attribute_name; do
    report_adjust_setting "Set system-scoped state $GENOMAC_STATE_USER_ATTRIBUTE_PREFIX for user $short_name with attribute $attribute_name"
    set_system_state_for_user_attribute "$short_name" "$attribute_name"
  done < <(attribute_names_from_user_spec_json "$user_spec_json")

  report_end_phase_standard
}

function get_1Password_key_from_delimited_state_string_DEPRECATED(){
  # Get the 1Password item key from a delimited volume-1Pkey state string
  # See construct_state_string_for_volume_1password_key_pending_creation() for background
  report_start_phase_standard
  local state_string="$1"
  local op_key

  report_fail "Doesn’t conform to new delimiter system"
  return 1

  op_key="${state_string##*${GENOMAC_STATE_STRING_DELIMITER_B}}"

  print -- "$op_key"
  
  report_end_phase_standard
}
