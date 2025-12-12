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
  local repo_slug="tylerhall/Alan"
  local pinned_version="v1.0"
  local zip_filename="Alan.zip"
  local applications_dir="/Applications"
  local bundle_id="studio.retina.Alan"

  # Memorialize whether Alan was already running
  local alan_was_running=false
  if osascript -e "application id \"$bundle_id\" is running" 2>/dev/null | grep -qi true; then
    alan_was_running=true
  fi

  install_app_from_github_zip \
    "$app_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$zip_filename" \
    "$applications_dir" \
    "$bundle_id"

  # Relaunch Alan if it had already been running, just in case it got upgraded (which would
  # would have quit Alan)
  if [[ "$alan_was_running" == true ]]; then
    report_action_taken "Alan was running before potential upgrade; relaunching ${bundle_id}"
    # Launch in background; fall back without -j if needed.
    open -gj -b "$bundle_id" 2>/dev/null || open -g -b "$bundle_id"
    success_or_not
  fi

  report_end_phase_standard
}
