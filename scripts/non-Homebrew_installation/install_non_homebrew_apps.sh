#!/usr/bin/env zs

# Source the function file(s)
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_alan_app.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_app_from_github_zip.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_tool_via_package_from_github.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_default_browser_cli.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_utiluti.sh"
source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_visualdiffer.sh"

function conditionally_install_non_homebrew_apps() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_NON_HOMEBREW_APPS_HAVE_BEEN_INSTALLED" \
    install_non_homebrew_apps \
    "Skipping installation of non-Homebrew apps, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_non_homebrew_apps() {
  # Installs non-Homebrew apps (direct downloads such as Alan.app)
  report_start_phase_standard

  # Installs Alan.app to highlight prominently the active window
  install_alan_app

  # Install utiluti utility to set the default app associated with document types, etc.
  install_utiluti

  # Install default-browser utility to set the default browser
  install_default_browser_cli

  # Install VisualDiffer.app to diff two text files
  install_visualdiffer

  report_end_phase_standard
}
