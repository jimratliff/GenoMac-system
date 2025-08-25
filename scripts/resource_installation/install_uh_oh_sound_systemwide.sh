# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please source install_uh_oh_sound_systemwide.sh from an initialized environment."
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

  # Assume sound file is committed in GenoMac-system repo at:
  # $GENOMAC_SYSTEM_LOCAL_DIRECTORY/resources/sounds/alerts/Uh_oh.aiff
  local source_path="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources/sounds/alerts/${sound_name}"

  report_action_taken "Verify that source sound file exists"
  if [[ ! -f "$source_path" ]]; then
    report_fail "Source sound file not found at: $source_path"
    report_end_phase_standard
    return 1
  fi
  report_success "Source file verified: $source_path"

  keep_sudo_alive

  report_action_taken "Ensure destination folder exists: $system_alerts_dir"
  sudo mkdir -p "$system_alerts_dir" ; success_or_not

  report_action_taken "Copy ${sound_name} to ${system_alerts_dir} (idempotent)"
  if [[ ! -e "$destination_path" ]] || ! cmp -s "$source_path" "$destination_path"; then
    sudo cp -f "$source_path" "$destination_path" ; success_or_not
    report_success "Installed or updated ${sound_name}"
  else
    report_success "${sound_name} already up to date"
  fi

  report_action_taken "Set ownership and permissions on ${destination_path}"
  sudo chown root:wheel "$destination_path" ; success_or_not
  sudo chmod 644 "$destination_path" ; success_or_not

  report_end_phase_standard
  return 0
}
