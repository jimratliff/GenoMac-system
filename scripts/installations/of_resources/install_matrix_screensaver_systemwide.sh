#!/usr/bin/env zsh

function install_matrix_screensaver_systemwide() {
  # Installs Monroe Williams’ “MatrixDownload” screensaver systemwide.
  # 🗑️ To uninstall: sudo rm -rf "/Library/Screen Savers/Matrix.saver"
  #
  # 🚨 Warning: As of 11/29/2025, this Matrix screensaver isn’t reliable on macOS 26 Tahoe.
  # “Doesn't work with macOS Tahoe 26 RC (release candidate) #24,” 
  # https://github.com/monroewilliams/MatrixDownload/issues/24
  #
  # NOTE: On 1/11/2026, it seemed to be working well on macOS 26. Let’s watch to see how long it lasts.
  # NOTE: On 1/20/2026, it works when triggered by elapsed time, but not when attempting to trigger via hot corner.

  report_start_phase_standard

  local screensaver_name="Matrix.saver"
  local repo_slug="monroewilliams/MatrixDownload"
  local pinned_tag="1.1.5"
  local zip_filename="Matrix.saver.zip"
  local system_screensaver_dir="/Library/Screen Savers"

  install_bundle_from_github_zip \
    "$screensaver_name" \
    "$repo_slug" \
    "$pinned_tag" \
    "$zip_filename" \
    "$system_screensaver_dir"

  report_end_phase_standard
}
