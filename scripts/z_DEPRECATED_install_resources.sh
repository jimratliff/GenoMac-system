#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

# Template for entry-point scripts

source "${HOME}/.genomac-system/scripts/0_initialize_me.sh"

# Source function(s)
# Resource-related scripts should be placed in GenoMac-system/scripts/resource_installation
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_fira_code_nerd_font_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_matrix_screensaver_systemwide.sh"
source "${GMS_RESOURCE_INSTALLATION_SCRIPTS_DIR}/install_uh_oh_sound_systemwide.sh"

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

function main() {
  install_resources_systemwide
  dump_accumulated_warnings_failures
}

main
