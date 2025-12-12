#!/bin/zsh

# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please ensure helpers.sh has been loaded before sourcing helper_install_app_from_github_zip.sh."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

set -euo pipefail

# is-at-least is builtin to zsh but must be explicitly loaded before called.
autoload -Uz is-at-least

# Returns 0 iff "$have" >= "$min" (semantic version comparison)
function version_ge() {
  local min="$1"
  local have="$2"
  is-at-least "$min" "$have"
}

############################## GENERIC HELPER ##############################

# install_app_from_github_zip
#
# Downloads a macOS .zip from a GitHub repo and installs the contained .app bundle.
#
# This helper is intended for apps like Alan.app, which is not available via Homebrew but is available
# directly as a zip-ped .app from a GitHub repo.
#
# Arguments:
#   1: app_name         – app bundle name, e.g. "Alan.app"
#   2: repo_slug        – "owner/repo", e.g. "tylerhall/Alan"
#   3: pinned_tag       – Git tag, e.g. "v1.0"
#   4: zip_filename     – exact .zip filename in that release, e.g. "Alan.zip"
#   5: applications_dir – destination directory, e.g. "/Applications"
#   6: bundle_id        – bundle identifier, e.g. "com.tylerhall.Alan"
#
# Behavior:
#   - Reads installed version from app's Info.plist (CFBundleShortVersionString or CFBundleVersion)
#   - If installed == pinned  → skip
#   - If installed < pinned   → upgrade (download + install)
#   - If installed > pinned   → warn and skip (no downgrade)
#   - Always checks GitHub for a newer tag and warns if pinned is behind.
#
function install_app_from_github_zip() {

  report_start_phase_standard

  local app_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"       # Git tag, e.g. "v1.0"
  local zip_filename="$4"
  local applications_dir="$5"
  local bundle_id="$6"

  local destination_path="${applications_dir}/${app_name}"

  # Derive the app's expected version from the tag (strip leading 'v' if present)
  local pinned_app_version="${pinned_tag#v}"

  local installed_version=""

  if [[ -d "$destination_path" ]]; then
    installed_version="$(
      defaults read "${destination_path}/Contents/Info" CFBundleShortVersionString 2>/dev/null \
        || defaults read "${destination_path}/Contents/Info" CFBundleVersion 2>/dev/null \
        || true
    )"

    if [[ -n "$installed_version" ]]; then
      if [[ "$installed_version" == "$pinned_app_version" ]]; then
        report_action_taken "${app_name} already at version ${installed_version}; skipping reinstall"
        success_or_not
        report_end_phase_standard
        return 0
      fi

      if version_ge "$pinned_app_version" "$installed_version"; then
        # installed_version < pinned_app_version → upgrade
        report_action_taken "Upgrading ${app_name} from ${installed_version} to ${pinned_app_version}"
        success_or_not
        # fall through to download + install
      else
        # installed_version > pinned_app_version → do not downgrade
        report_warning "${app_name} installed version ${installed_version} is newer than pinned ${pinned_app_version}; not downgrading"
        report_end_phase_standard
        return 0
      fi
    fi
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' EXIT

  local zip_url="https://github.com/${repo_slug}/releases/download/${pinned_tag}/${zip_filename}"

  report_action_taken "Downloading ${app_name} ${pinned_tag} from ${zip_url}"
  curl -fsSL "$zip_url" -o "$temp_dir/$zip_filename" ; success_or_not

  report_action_taken "Unzipping ${zip_filename}"
  unzip -q "$temp_dir/$zip_filename" -d "$temp_dir" ; success_or_not

  report_action_taken "If running, I will quit app $bundle_id"
  quit_app_by_bundle_id_if_running $bundle_id
  
  report_action_taken "Removing any existing ${app_name} at ${destination_path}"
  sudo rm -rf "$destination_path" ; success_or_not

  report_action_taken "Installing ${app_name} to ${destination_path}"
  sudo cp -R "$temp_dir/$app_name" "$destination_path" ; success_or_not

  report_action_taken "Setting permissions and ownership on ${destination_path}"
  sudo chown -R root:wheel "$destination_path" ; success_or_not
  sudo chmod -R go-w "$destination_path" ; success_or_not

  # Optional: check for newer GitHub release (best-effort)
  report_action_taken "Checking for newer ${app_name} release on GitHub"
  local latest_tag
  latest_tag="$(gh release view --repo "$repo_slug" --json tagName -q .tagName 2>/dev/null || true)"
  success_or_not

  if [[ -n "$latest_tag" && "$latest_tag" != "$pinned_tag" ]]; then
    report_warning "A newer version of ${app_name} is available: ${latest_tag}. You are pinned to ${pinned_tag}."
  fi

  report_end_phase_standard
  return 0
}
