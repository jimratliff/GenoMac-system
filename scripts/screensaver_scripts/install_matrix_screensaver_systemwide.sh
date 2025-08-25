# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please source `install_fira_code_nerd_font_systemwide.sh` first."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################

function install_matrix_screensaver_systemwide() {
  report_start_phase_standard

  local screensaver_name="Matrix.saver"
  local pinned_version="1.1.5"
  local zip_filename="Matrix.saver.zip"
  local zip_url="https://github.com/monroewilliams/MatrixDownload/releases/download/${pinned_version}/${zip_filename}"
  local system_screensaver_dir="/Library/Screen Savers"
  local destination_path="${system_screensaver_dir}/${screensaver_name}"

  local temp_dir; temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT

  report_action_taken "Download MatrixDownload v$pinned_version from GitHub"
  curl -fsSL "$zip_url" -o "$temp_dir/$zip_filename"
  success_or_not $? "Downloaded ${zip_filename}"

  report_action_taken "Unzip ${zip_filename}"
  unzip -q "$temp_dir/$zip_filename" -d "$temp_dir"
  success_or_not $? "Unzipped to temporary directory"

  report_action_taken "Read version from downloaded .saver Info.plist"
  local downloaded_version
  downloaded_version="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$temp_dir/$screensaver_name/Contents/Info.plist" 2>/dev/null)"
  success_or_not $? "Downloaded screensaver reports version: ${downloaded_version}"

  if [[ -f "$destination_path/Contents/Info.plist" ]]; then
    report_action_taken "Check if screensaver is already installed"
    local installed_version
    installed_version="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$destination_path/Contents/Info.plist" 2>/dev/null)"
    success_or_not $? "Installed screensaver reports version: ${installed_version}"

    if [[ "$installed_version" == "$downloaded_version" ]]; then
      report_success "Screensaver is already up-to-date (v${installed_version})"
      report_end_phase_standard
      return 0
    fi
  fi

  report_action_taken "Install or replace screensaver at: $destination_path"
  sudo rm -rf "$destination_path"
  sudo cp -R "$temp_dir/$screensaver_name" "$destination_path"
  success_or_not $? "Installed or replaced Matrix.saver in $system_screensaver_dir"

  report_action_taken "Set permissions and ownership"
  sudo chown -R root:wheel "$destination_path"
  sudo chmod -R go-w "$destination_path"
  success_or_not $? "Ownership and permissions set"

  report_action_taken "Check for newer version of MatrixDownload"
  local latest_version
  latest_version="$(gh release view --repo monroewilliams/MatrixDownload --json tagName -q .tagName 2>/dev/null || true)"
  if [[ -n "$latest_version" && "$latest_version" != "$pinned_version" ]]; then
    report_warning "A newer version of MatrixDownload is available: v${latest_version}"
  fi

  report_end_phase_standard

  return 0

  # 🗑️ To uninstall:
  # sudo rm -rf "/Library/Screen Savers/Matrix.saver"
}
