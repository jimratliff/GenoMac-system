# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please source install_resources.sh first."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################

function install_uh_oh_sound_systemwide() {
  # Installs the Uh_oh.aiff alert sound systemwide (all users)
  
  report_start_phase_standard
  
  local sound_name="Uh_oh.aiff"
  local system_alerts_dir="/Library/Audio/Sounds/Alerts"
  local destination_path="${system_alerts_dir}/${sound_name}"
  
  # Construct full source path for this specific repo
  local source_path="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources/sounds/alerts/${sound_name}"
  
  # Use the helper function to copy the resource
  copy_resource_between_local_directories \
    "$source_path" \
    "$destination_path" \
    --systemwide
  
  local result=$?
  
  report_end_phase_standard
  return $result
}
