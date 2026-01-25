#!/usr/bin/env zsh

function install_visualdiffer() {
  # Installs VisualDiffer macOS app, by Davide Ficano, et al., into /Applications.
  # Release page: https://github.com/Visualdiffer/visualdiffer/releases

  report_start_phase_standard

  local app_name="VisualDiffer.app"
  local repo_slug="visualdiffer/visualdiffer"
  local pinned_version="v2.1.0"
  local zip_filename="VisualDiffer-2.1.0.zip"
  local applications_dir="/Applications"
  local bundle_id="com.visualdiffer"

  install_app_from_github_zip \
    "$app_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$zip_filename" \
    "$applications_dir" \
    "$bundle_id"

  report_end_phase_standard
}
