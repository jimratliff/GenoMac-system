#!/usr/bin/env zsh

# Source the function file(s)
# source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/helpers_for_non_homebrew_installations.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_alan_app.sh"
# source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_app_from_github_zip.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_hiarcs_chess_explorer_pro.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_officetime.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_omnioutliner.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_proton_drive.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_tool_via_package_from_github.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_default_browser_cli.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_utiluti.sh"
# source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_visualdiffer.sh"
# source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_witch_prefpane.sh"

function conditionally_install_non_homebrew_apps_sans_Dropbox() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_NON_HOMEBREW_APPS_SANS_DROPBOX_HAVE_BEEN_INSTALLED" \
    install_non_homebrew_apps_sans_Dropbox \
    "Skipping installation of non-Homebrew apps that don’t require Dropbox, because this installation was performed earlier this session."

  report_end_phase_standard
}

function conditionally_install_non_homebrew_apps_with_Dropbox() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_NON_HOMEBREW_APPS_WITH_DROPBOX_HAVE_BEEN_INSTALLED" \
    install_non_homebrew_apps_with_Dropbox \
    "Skipping installation of non-Homebrew apps that require Dropbox, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_non_homebrew_apps_sans_Dropbox() {
  # Installs non-Homebrew apps that don’t require USER_CONFIGURER to have Dropbox configured (direct downloads such as Alan.app)
  report_start_phase_standard

  report_action_taken "Install Alan.app to highlight prominently the active window"
  install_alan_app                                 # scripts/installations/non_homebrew/install_alan_app.sh

  report_action_taken "Install utiluti utility to set the default app associated with document types, etc."
  install_utiluti                                  # scripts/installations/non_homebrew/install_utiluti.sh

  report_action_taken "Install default-browser utility to set the default browser"
  install_default_browser_cli                      # scripts/installations/non_homebrew/install_default_browser_cli.sh

  report_action_taken "Conditionally install HIARCS Chess Explorer Pro"
  conditionally_install_hiarcs_chess_explorer_pro  # scripts/installations/non_homebrew/install_hiarcs_chess_explorer_pro.sh

  report_action_taken "Conditionally install OfficeTime"
  conditionally_install_officetime                 # scripts/installations/non_homebrew/install_officetime.sh

  # Installing VisualDiffer in this way is DEPRECATED because it’s available from Homebrew
  # report_action_taken "Install VisualDiffer.app to diff two text files"
  # install_visualdiffer

  report_end_phase_standard
}

function install_non_homebrew_apps_with_Dropbox() {
  # Installs non-Homebrew apps that require USER_CONFIGURER to have Dropbox configured (direct downloads such as Alan.app).
  report_start_phase_standard

  report_action_taken "Install Proton Drive app"
  install_proton_drive                                 # scripts/installations/non_homebrew/install_proton_drive.sh

  report_action_taken "Install discontinued Mac Apple Store version of OmniOutliner 5"
  install_omnioutliner                                 # scripts/installations/non_homebrew/install_omnioutliner.sh

  report_end_phase_standard
}
