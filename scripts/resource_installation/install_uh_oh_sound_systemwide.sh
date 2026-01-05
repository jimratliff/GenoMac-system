#!/bin/zsh

function install_uh_oh_sound_systemwide() {
  # Installs the Uh_oh.aiff alert sound systemwide (all users)
  
  report_start_phase_standard
  
  # Construct path to stored custom alert-sound file
  # Hint: CUSTOM_ALERT_SOUND_FILENAME="Uh_oh.aiff"
  # Hint: GENOMAC_SYSTEM_LOCAL_RESOURCE_DIRECTORY="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources"
  local source_path="${GENOMAC_SYSTEM_LOCAL_RESOURCE_DIRECTORY}/sounds/alerts/${CUSTOM_ALERT_SOUND_FILENAME}"

  # Destination directory is macOS-standard directory for storing available alert sounds
  # Hint: SYSTEM_ALERT_SOUNDS_DIRECTORY="/Library/Audio/Sounds/Alerts"
  local destination_path="${SYSTEM_ALERT_SOUNDS_DIRECTORY}/${sound_name}"
  
  # Use the helper function to copy the resource
  copy_resource_between_local_directories \
    "$source_path" \
    "$destination_path" \
    --systemwide
  
  local result=$?
  
  report_end_phase_standard
  return $result
}
