#!/usr/bin/env zsh

function conditionally_interactive_create_volumes_for_user_home_directories() {
  # Creates new volumes to house users’ home directories.
  
  report_start_phase_standard

  local op_item_key
  local volume_name

  local -i i

  local -a volume_name_op_item_key_pairs_to_create
  
  collect_volume_name_op_item_key_pairs_for_volumes_pending_certified_creation
  volume_name_op_item_key_pairs_to_create=("${reply[@]}")
  
  if (( ! ${#volume_name_op_item_key_pairs_to_create[@]} )); then
    report "No volumes need to be created."
    return 0
  fi
  
  for (( i = 1; i <= ${#volume_name_op_item_key_pairs_to_create[@]}; i += 2 )); do
    volume_name="${volume_name_op_item_key_pairs_to_create[i]}"
    op_item_key="${volume_name_op_item_key_pairs_to_create[i+1]}"
    conditionally_interactive_create_a_volume "$volume_name" "$op_item_key"
  done
  
  report_end_phase_standard
}

function conditionally_interactive_create_a_volume() {
  # Create specified volume, encrypted by passphrase referenced by 1Password item.
  
  report_start_phase_standard
  local volume_name="${1;?missing volume_name}"
  local op_item_key="${2:?missing op_item_key}"
  
  local container_name
  local startup_container

  if volume_name_is_startup_volume_signifier "$volume_name"; then
    # NOTE: This shouldn’t be reached, because the is-necessary state never should have been created for the
    #       the startup volume. (Function conditionally_mark_volume_is_necessary() tests for startup volume.)
    report "The volume name “$volume_name” signifies the startup volume, which necessarily exists.${NEWLINE}Nothing further to record."
    report_warning "PROGRAMMER ERROR?? Volume name “$volume_name” shouldn’t have been flagged as a necessary non-startup volume to be created."
    unmark_volume_as_pending_creation “$volume_name” "$op_item_key"
    report_end_phase_standard
    return 0
  fi

  if volume_name_is_mounted "$volume_name"; then
    report "The “volume name” “$volume_name” is currently mounted, and therefore exists.${NEWLINE}Nothing further to record."
    report_warning "Although “volume name” “$volume_name” is currently mounted, I can’t guarantee it’s encrypted${NEWLINE}by the passphrase referenced by the 1Password item “$op_item_key”. That’s for you to ensure."
    unmark_volume_as_pending_creation “$volume_name” "$op_item_key"
    report_end_phase_standard
    return 0
  fi

  report "The “volume name” “$volume_name” is marked as needing to be created and${NEWLINE}encrypted using the passphrase referenced by the 1Password item “$op_item_key”."
  startup_container="$(determine_startup_container)"
  volume_creation_mode="$(get_value_from_numbered_choices \
    "How do you want to deal with the pending-to-create volume “$volume_name”?" \
    "Create and encrypt the volume on the startup container (${startup_container})" "CREATE_ON_STARTUP_CONTAINER" \
    "Create and encrypt the volume on a different container" "CREATE_ON_DIFFERENT_CONTAINER" \
    "PUNT. Leave it pending for now, move on, and I’ll deal with it later" "PUNT"
    )"

  case "$volume_creation_mode" in
    CREATE_ON_STARTUP_CONTAINER)
      # Create and encrypt the volume on the startup container.
      container_name="$startup_container"
      create_and_encrypt_volume_on_container "$volume_name" "$op_item_key" "$container_name"
      unmark_volume_as_pending_creation “$volume_name” "$op_item_key"
      ;;
    
    CREATE_ON_DIFFERENT_CONTAINER)
      # Create and encrypt the volume on a different container.
      report "It’s your responsibility to create (now, if not before) the container you want to use."
      container_name="$(get_confirmed_answer_to_question "Name of container?")"
      create_and_encrypt_volume_on_container "$volume_name" "$op_item_key" "$container_name"
      unmark_volume_as_pending_creation “$volume_name” "$op_item_key"
      ;;
    
    PUNT)
      # Leave the volume pending for now and move on.
      report_end_phase_standard
      return 0
      ;;
    
    *)
      report_fail "Unrecognized volume-creation choice: “${volume_creation_mode}”"
      return 1
      ;;
  esac
  report_end_phase_standard
  return 0
}

# DEPRECATED, replaced by construct_map_from_volume_name_to_op_item_key()
# function construct_map_from_volume_name_to_op_item_key_from_pending_creation_state_strings() {
#   # Returns associative array from array of volumes-pending-creation state strings, where
#   # the associative array maps volume_name to op_item_key.
#   #
#   # If multiple state strings share a common volume_name, generate fatal error.
#   
#   report_start_phase_standard
#   local -a pending_volume_state_strings
#   pending_volume_state_strings=("$@")
# 
#   local -A op_item_key_from_volume_name
#   local state_string
#   local volume_name
#   local op_item_key
#   local error_string
# 
#   for state_string in "${pending_volume_state_strings[@]}"; do
#     volume_name=$(volume_name_from_pending_volume_state_string "$state_string")
#     op_item_key=$(op_item_key_from_pending_volume_state_string "$state_string")
# 
#     if [[ -v 'op_item_key_from_volume_name[$volume_name]' ]]; then
#       report_fail "Multiple pending-creation states for volume ${volume_name}"
#       return 1
#     fi
# 
#     op_item_key_from_volume_name[$volume_name]="$op_item_key"
#   done
#   reply=("${(@kv)op_item_key_from_volume_name}")
#   
#   report_end_phase_standard
# }
