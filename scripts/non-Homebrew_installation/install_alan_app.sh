# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please ensure helpers.sh has been loaded before sourcing install_alan_app.sh."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################

function install_alan_app() {
  # Installs Tyler Hall’s “Alan” macOS app into /Applications.
  # 🗑️ To uninstall: sudo rm -rf "/Applications/Alan.app"

  report_start_phase_standard

  local app_name="Alan.app"
  local pinned_version="v1.0"
  local zip_filename="Alan.zip"
  local zip_url="https://github.com/tylerhall/Alan/releases/download/${pinned_version}/${zip_filename}"
  local applications_dir="/Applications"
  local destination_path="${applications_dir}/${app_name}"

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' EXIT

  report_action_taken "Downloading ${app_name} v${pinned_version} from GitHub"
  curl -fsSL "$zip_url" -o "$temp_dir/$zip_filename" ; success_or_not

  report_action_taken "Unzipping ${zip_filename}"
  unzip -q "$temp_dir/$zip_filename" -d "$temp_dir" ; success_or_not

  report_action_taken "Removing any existing ${app_name} at ${destination_path}"
  sudo rm -rf "$destination_path" ; success_or_not

  report_action_taken "Installing ${app_name} to ${destination_path}"
  sudo cp -R "$temp_dir/$app_name" "$destination_path" ; success_or_not

  report_action_taken "Setting permissions and ownership on ${destination_path}"
  sudo chown -R root:wheel "$destination_path" ; success_or_not
  sudo chmod -R go-w "$destination_path" ; success_or_not

  report_action_taken "Checking for newer version on GitHub"
  local latest_version
  latest_version="$(gh release view --repo tylerhall/Alan --json tagName -q .tagName 2>/dev/null || true)"
  success_or_not

  if [[ -n "$latest_version" && "$latest_version" != "$pinned_version" ]]; then
    report_warning "A newer version of ${app_name} is available: v${latest_version}. It is up to you to install it."
  fi

  report_end_phase_standard
  return 0
}
