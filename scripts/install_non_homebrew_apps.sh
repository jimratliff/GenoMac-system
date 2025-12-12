#!/bin/zsh

# Installs non-Homebrew apps (direct downloads such as Alan.app).

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR).
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Non-Homebrew app–related scripts live here:
#   scripts/non-Homebrew_installation/
NON_HOMEBREW_APPS_FUNCTIONS_DIR="${this_script_dir}/non-Homebrew_installation"

# Print assigned paths for diagnostic purposes
printf "\n📂 Path diagnostics:\n"
printf "this_script_dir:                    %s\n" "$this_script_dir"
printf "GENOMAC_HELPER_DIR:                 %s\n" "$GENOMAC_HELPER_DIR"
printf "NON_HOMEBREW_APPS_FUNCTIONS_DIR:    %s\n\n" "$NON_HOMEBREW_APPS_FUNCTIONS_DIR"

# Source the function file(s)
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_alan_app.sh"
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_app_from_github_zip.sh"
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_tool_via_package_from_github.sh"
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_default_browser_cli.sh"
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_utiluti.sh"
source "${NON_HOMEBREW_APPS_FUNCTIONS_DIR}/install_visualdiffer.sh"

############################## BEGIN SCRIPT PROPER ##############################
function install_non_homebrew_apps() {
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

function main() {
  install_non_homebrew_apps
  dump_accumulated_warnings_failures
}

main
