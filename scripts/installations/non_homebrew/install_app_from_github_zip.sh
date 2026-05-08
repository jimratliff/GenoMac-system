#!/bin/zsh

function install_app_from_github_zip() {
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
  #   - Performs a best-effort GitHub release check
  #   - If GitHub's latest release tag differs from pinned_tag, warns but does not auto-upgrade.
  #   - If the app is not installed → install pinned version
  #   - If installed, reads version from app's Info.plist
  #     - If installed < pinned  → upgrade to pinned version
  #     - If installed == pinned → skip
  #     - If installed > pinned  → warn and skip; do not downgrade
  #   - If GitHub's latest release tag differs from pinned_tag, warns that a different release exists.
  #   - Does not auto-upgrade to GitHub's latest release; upgrading requires deliberately changing pinned_tag.

  report_start_phase_standard

  local app_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"       # Git tag, e.g. "v1.0"
  local zip_filename="$4"
  local applications_dir="$5"
  local bundle_id="$6"

  warn_if_github_latest_release_differs_from_pinned \
    "$app_name" \
    "$repo_slug" \
    "$pinned_tag"

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
        # pinned_app_version > installed_version → upgrade
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
  quit_app_by_bundle_id_if_running "$bundle_id"
  
  report_action_taken "Removing any existing ${app_name} at ${destination_path}"
  sudo rm -rf "$destination_path" ; success_or_not

  report_action_taken "Installing ${app_name} to ${destination_path}"
  sudo cp -R "$temp_dir/$app_name" "$destination_path" ; success_or_not

  report_action_taken "Setting permissions and ownership on ${destination_path}"
  sudo chown -R root:wheel "$destination_path" ; success_or_not
  sudo chmod -R go-w "$destination_path" ; success_or_not

  report_end_phase_standard
  return 0
}
