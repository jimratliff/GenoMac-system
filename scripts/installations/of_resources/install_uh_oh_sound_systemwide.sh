#!/bin/zsh

function conditionally_install_uh_oh_sound_systemwide() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_ALERT_SOUND_HAS_BEEN_INSTALLED" \
    install_uh_oh_sound_systemwide \
    "Skipping installation of Uh oh! alert sound, because it was installed in the past."
  
  report_end_phase_standard
}

function install_uh_oh_sound_systemwide() {
  # Installs the Uh_oh.aiff alert sound systemwide (all users)
  
  report_start_phase_standard
  
  # Construct path to stored custom alert-sound file
  # Hint: CUSTOM_ALERT_SOUND_FILENAME="Uh_oh.aiff"
  # Hint: GMS_RESOURCES="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources"
  local source_path="${GMS_RESOURCES}/sounds/alerts/${CUSTOM_ALERT_SOUND_FILENAME}"

  # Destination directory is macOS-standard directory for storing available alert sounds
  # Hint: SYSTEM_ALERT_SOUNDS_DIRECTORY="/Library/Audio/Sounds/Alerts"
  # Hint: PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE="${SYSTEM_ALERT_SOUNDS_DIRECTORY}/${CUSTOM_ALERT_SOUND_FILENAME}"
  local destination_path="${PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE}"
  
  # Use the helper function to copy the resource
  copy_resource_between_local_directories \
    "$source_path" \
    "$destination_path" \
    --systemwide
  
  local result=$?
  
  report_end_phase_standard
  return $result
}
