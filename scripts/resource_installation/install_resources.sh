#!/usr/bin/env zs

# Source function(s)
# Resource-related scripts should be placed in GenoMac-system/scripts/resource_installation
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_fira_code_nerd_font_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_matrix_screensaver_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_uh_oh_sound_systemwide.sh"

function conditionally_install_resources_systemwide() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_RESOURCES_HAVE_BEEN_INSTALLED" \
    install_non_homebrew_apps \
    "Skipping installation of resources, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_resources_systemwide() {
  report_start_phase_standard

  # Installs Fira Code Nerd Font
  install_fira_code_nerd_font_systemwide

  # Installs MatrixDownload screensaver
  install_matrix_screensaver_systemwide

  # Installs Uh_oh alert sound
  install_uh_oh_sound_systemwide

  report_end_phase_standard

}
