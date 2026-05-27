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
