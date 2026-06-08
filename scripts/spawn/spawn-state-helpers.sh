#!/usr/bin/env zsh

function mark_user_as_created(){
  # Set system-scoped state to mark user as having been created, with supplied volume of
  # user’s home directory.

  report_start_phase_standard
  local short_name="$1"
  local volume_name="$2"
  local state_string

  state_string="${GENOMAC_STATE_USER_EXISTS_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${user_name}${GENOMAC_STATE_STRING_DELIMITER_B}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_C}"
  set_genomac_system_state "$state_string"
  
  report_end_phase_standard
}

function set_system_states_for_user_attributes(){
  # Sets a system-scoped state for each attribute of user:
  # - First, those inherited from the user’s user-class
  # - Second, those user-specific attributes specified in the user’s user_spec_json, which is supplied as $1.
  # - Third, a state (prefix: $GENOMAC_STATE_USER_CLASS_PREFIX) for the user’s user-class.
  
  report_start_phase_standard
  local user_spec_json="${1:?missing user_spec_json}"

  local attribute_name
  local short_name
  local user_class
  
  short_name="$(get_short_name_from_user_spec_json "$user_spec_json")"
  user_class="$(get_user_class_from_user_spec_json "$user_spec_json")"

  # TODO: Delete all system-scoped attribute states for this user so that they will be assigned on a clean state.

  # Sets system-scoped state for special-case attribute equal to the user’s user-class
  report_adjust_setting "Set system-scoped state $GENOMAC_STATE_USER_ATTRIBUTE_PREFIX for user $short_name with user class $user_class"
  set_system_state_for_user_class "$short_name" "$user_class" # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh

  # Sets system-scoped states for attributes inherited from the user’s user-class
  while IFS= read -r attribute_name; do
    report_adjust_setting "Set system-scoped state $GENOMAC_STATE_USER_ATTRIBUTE_PREFIX for user $short_name with user-class-derived attribute $attribute_name"
    set_system_state_for_user_attribute "$short_name" "$attribute_name"
  done < <(attribute_names_from_user_class "$user_class")

  # Sets system-scoped states for attributes specific to the user
  while IFS= read -r attribute_name; do
    report_adjust_setting "Set system-scoped state $GENOMAC_STATE_USER_ATTRIBUTE_PREFIX for user $short_name with attribute $attribute_name"
    set_system_state_for_user_attribute "$short_name" "$attribute_name" # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh
  done < <(attribute_names_from_user_spec_json "$user_spec_json")

  report_end_phase_standard
}

function attribute_names_from_user_spec_json() {
  local user_spec_json="${1:?missing user_spec_json}"

  jq -r '
    (.attributes // [])
    | .[]
  ' <<<"$user_spec_json"
}

function attribute_names_from_user_class() {
  # Prints each attribute associated with a user_class, one per line.

  local user_class="${1:?missing user_class}"
  local attributes_json

  attributes_json="${user_attributes_from_user_class[$user_class]-[]}"

  jq -r '.[]' <<<"$attributes_json"
}

#############################################
#        EVERYTHING BELOW THIS IS DEPRECATED
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
