#!/bin/zsh

function install_default_browser_cli() {
  # Install default-browser from macadmins
  #
  # NOTE: You need to set pkg_filename to match the *actual* asset name
  # from the v1.0.18 release page.
  
  report_start_phase_standard

  local tool_name="default-browser"
  local repo_slug="macadmins/default-browser"
  local pinned_version="v1.0.18"
  local pkg_filename="default-browser.pkg"
  local pkg_id="com.github.macadmins.default-browser"
  local binary_path="/opt/macadmins/bin/default-browser"

  install_tool_via_package_from_github \
    "$tool_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$pkg_filename" \
    "$pkg_id" \
    "$binary_path"

  report_end_phase_standard
}
