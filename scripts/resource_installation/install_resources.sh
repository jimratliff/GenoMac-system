#!/usr/bin/env zs

# Source function(s)
# Resource-related scripts should be placed in GenoMac-system/scripts/resource_installation
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS}/install_fira_code_nerd_font_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS}/install_matrix_screensaver_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS}/install_uh_oh_sound_systemwide.sh"

function conditionally_install_resources_systemwide() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_RESOURCES_HAVE_BEEN_INSTALLED" \
    install_resources_systemwide \
    "Skipping installation of resources, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_resources_systemwide() {
  report_start_phase_standard

  # Installs Fira Code Nerd Font
  report_action_taken "Install Fira Code Nerd font"
  install_fira_code_nerd_font_systemwide

  report_action_taken "Install MatrixDownload screensaver"
  install_matrix_screensaver_systemwide

  report_action_taken "Install ‘Uh oh!’ alert sound"
  install_uh_oh_sound_systemwide

  report_end_phase_standard
}
