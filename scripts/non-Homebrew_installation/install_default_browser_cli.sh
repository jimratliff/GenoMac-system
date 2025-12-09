#!/bin/zsh

# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please ensure helpers.sh has been loaded before sourcing install_tool_via_package_from_github.sh."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Fail early on unset variables or command failure
set -euo pipefail

############################## SPECIFIC INSTALLERS ##############################

# 1) default-browser (macadmins)
#
# NOTE: You need to set pkg_filename to match the *actual* asset name
# from the v1.0.18 release page. The illustrative name below may need
# tweaking once you eyeball the Releases tab.
#
function install_default_browser_cli() {
  report_start_phase_standard

  local tool_name="default-browser"
  local repo_slug="macadmins/default-browser"
  local pinned_version="v1.0.18"
  local pkg_filename="default-browser.pkg"
  local pkg_id="com.github.macadmins.default-browser"
  local binary_path="/opt/macadmins/bin/default-browser"

  install_package_from_github \
    "$tool_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$pkg_filename" \
    "$pkg_id" \
    "$binary_path"

  report_end_phase_standard
}
