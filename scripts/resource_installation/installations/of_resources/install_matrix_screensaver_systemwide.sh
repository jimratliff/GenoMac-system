#!/usr/bin/env zs

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
  local pinned_version="1.1.5"
  local zip_filename="Matrix.saver.zip"
  local zip_url="https://github.com/monroewilliams/MatrixDownload/releases/download/${pinned_version}/${zip_filename}"
  local system_screensaver_dir="/Library/Screen Savers"
  local destination_path="${system_screensaver_dir}/${screensaver_name}"

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' EXIT

  report_action_taken "Downloading MatrixDownload v$pinned_version from GitHub"
  curl -fsSL "$zip_url" -o "$temp_dir/$zip_filename" ; success_or_not

  report_action_taken "Unzipping ${zip_filename}"
  unzip -q "$temp_dir/$zip_filename" -d "$temp_dir" ; success_or_not

  # Skip installation if already installed and identical
  if [[ -d "$destination_path" ]] && diff -rq "$temp_dir/$screensaver_name" "$destination_path" &>/dev/null; then
    report_action_taken "MatrixDownload v$pinned_version already installed and unchanged — skipping"
    report_end_phase_standard
    return 0
  fi

  report_action_taken "Installing $screensaver_name (overwrite if necessary) at: $destination_path"
  report_action_taken "Removing any existing $screensaver_name at $destination_path"
  sudo rm -rf "$destination_path" ; success_or_not
  report_action_taken "Copying downloaded $screensaver_name to $destination_path"
  sudo cp -R "$temp_dir/$screensaver_name" "$destination_path" ; success_or_not

  report_action_taken "Setting permissions and ownership"
  sudo chown -R root:wheel "$destination_path" ; success_or_not
  sudo chmod -R go-w "$destination_path" ; success_or_not

  report_action_taken "Checking for newer version on GitHub"
  local latest_version
  latest_version="$(gh release view --repo monroewilliams/MatrixDownload --json tagName -q .tagName 2>/dev/null || true)"
  success_or_not

  if [[ -n "$latest_version" && "$latest_version" != "$pinned_version" ]]; then
    report_warning "A newer version of MatrixDownload is available: v${latest_version}. It is up to you to install it."
  fi

  report_end_phase_standard
  return 0
}
