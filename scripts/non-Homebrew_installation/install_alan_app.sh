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
  local repo_slug="tylerhall/Alan" \
  local pinned_version="v1.0"
  local zip_filename="Alan.zip"
  local applications_dir="/Applications"
  local bundle_id="com.tylerhall.Alan"

  install_app_from_github_zip \
    "$app_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$zip_filename" \
    "$applications_dir" \
    "$bundle_id"

  report_end_phase_standard
}
