#!/usr/bin/env zsh

function conditionally_install_witch_prefpane() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_WITCH_HAS_BEEN_INSTALLED" \
    install_witch_prefpane \
    "Skipping installation of Witch, because it has been installed in the past."

  report_end_phase_standard
}

function install_witch_prefpane() {
  # Installs Witch.prefPane system-wide from a zipped copy stored in the
  # GenoMac-system repo at .genomac-system/resources/witch/witch.zip.
  #
  # Installs to /Library/PreferencePanes/ so the pane is available to all users.
  #
  # This is a bootstrap function: the caller checks PERM_WITCH_HAS_BEEN_INSTALLED
  # before calling, and sets it after a successful return. Any existing prefPane
  # at the destination is overwritten.

  report_start_phase_standard

  local prefpane_name="Witch.prefPane"
  local zip_source="${GMS_RESOURCES}/witch/witch_prefpane.zip"
  local system_prefpanes_dir="/Library/PreferencePanes"
  local destination_path="${system_prefpanes_dir}/${prefpane_name}"

  if [[ ! -f "$zip_source" ]]; then
    report_warning "Zip not found at ${zip_source}"
    report_end_phase_standard
    return 1
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' EXIT

  report_action_taken "Unzipping ${zip_source}"
  unzip -q "$zip_source" -d "$temp_dir" ; success_or_not

  local source_path="${temp_dir}/${prefpane_name}"

  if [[ ! -d "$source_path" ]]; then
    source_path="$(find "$temp_dir" -name "$prefpane_name" -maxdepth 2 -type d | head -1)"
  fi

  if [[ -z "$source_path" || ! -d "$source_path" ]]; then
    report_warning "${prefpane_name} not found inside ${zip_source}"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Installing ${prefpane_name} to ${destination_path}"
  copy_resource_between_local_directories \
    "$source_path" \
    "$destination_path" \
    --systemwide
    local result=$?
  success_or_not

  report_end_phase_standard
  return $result
}
