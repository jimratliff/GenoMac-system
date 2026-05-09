#!/bin/zsh

# is-at-least is builtin to zsh but must be explicitly loaded before called.
autoload -Uz is-at-least

function warn_if_github_latest_release_differs_from_pinned() {
  local display_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"

  local latest_tag=""

  report_start_phase_standard

  if ! gh_is_authenticated; then
    report_warning "Skipping check for GitHub latest release tag for ${display_name} because gh isn’t available/authenticated"
    report_end_phase_standard
    return 0
  fi

  report_action_taken "Checking GitHub latest release tag for ${display_name}"
  if latest_tag="$(gh release view --repo "$repo_slug" --json tagName -q .tagName 2>/dev/null)"; then
    success_or_not

    if [[ -n "$latest_tag" && "$latest_tag" != "$pinned_tag" ]]; then
      report_warning "GitHub latest release tag for ${display_name} is ${latest_tag}; you are pinned to ${pinned_tag}. To upgrade, review the release, update the pinned tag/version, and run Hypervisor again."
    fi
  else
    success_or_not_NOT
    report_warning "Could not check GitHub latest release tag for ${display_name}; continuing with pinned ${pinned_tag}."
  fi
  report_end_phase_standard
  return 0
}

function install_bundle_from_github_zip() {
  # Downloads a macOS bundle from a GitHub release ZIP and installs it.
  #
  # Arguments:
  #   1: bundle_name      – bundle directory name, e.g. "Alan.app" or "Matrix.saver"
  #   2: repo_slug        – "owner/repo"
  #   3: pinned_tag       – Git tag, e.g. "v1.0" or "1.1.5"
  #   4: zip_filename     – exact .zip filename in that release
  #   5: destination_dir  – e.g. "/Applications" or "/Library/Screen Savers"
  #   6: bundle_id        – optional bundle id; if present, quit before replacing

  report_start_phase_standard

  local bundle_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"
  local zip_filename="$4"
  local destination_dir="$5"
  local bundle_id="${6:-}"

  local destination_path="${destination_dir}/${bundle_name}"
  local pinned_bundle_version="${pinned_tag#v}"
  local installed_version=""

  warn_if_github_latest_release_differs_from_pinned \
    "$bundle_name" \
    "$repo_slug" \
    "$pinned_tag"

  if [[ -d "$destination_path" ]]; then
    installed_version="$(
      defaults read "${destination_path}/Contents/Info" CFBundleShortVersionString 2>/dev/null \
        || defaults read "${destination_path}/Contents/Info" CFBundleVersion 2>/dev/null \
        || true
    )"
    report "Installed version: $installed_version"

    if [[ -n "$installed_version" ]]; then
      if [[ "$installed_version" == "$pinned_bundle_version" ]]; then
        report_action_taken "${bundle_name} already at version ${installed_version}; skipping reinstall"
        success_or_not
        report_end_phase_standard
        return 0
      fi

      if is_semantic_version_arg1_at_least_arg2 "$pinned_bundle_version" "$installed_version"; then
        report_action_taken "Upgrading ${bundle_name} from ${installed_version} to ${pinned_bundle_version}"
        success_or_not
      else
        report_warning "${bundle_name} installed version ${installed_version} is newer than pinned ${pinned_bundle_version}; not downgrading"
        report_end_phase_standard
        return 0
      fi
    else
      report_warning "${bundle_name} is installed, but its version is not provided; reinstalling pinned ${pinned_tag}"
    fi
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' EXIT

  local zip_url="https://github.com/${repo_slug}/releases/download/${pinned_tag}/${zip_filename}"

  report_action_taken "Downloading ${bundle_name} ${pinned_tag} from ${zip_url}"
  curl -fsSL "$zip_url" -o "$temp_dir/$zip_filename" ; success_or_not

  report_action_taken "Unzipping ${zip_filename}"
  unzip -q "$temp_dir/$zip_filename" -d "$temp_dir" ; success_or_not

  if [[ -n "$bundle_id" ]]; then
    report_action_taken "If running, I will quit bundle ${bundle_id}"
    quit_app_by_bundle_id_if_running "$bundle_id"
  fi

  report_action_taken "Removing any existing ${bundle_name} at ${destination_path}"
  sudo rm -rf "$destination_path" ; success_or_not

  report_action_taken "Installing ${bundle_name} to ${destination_path}"
  sudo cp -R "$temp_dir/$bundle_name" "$destination_path" ; success_or_not

  report_action_taken "Setting permissions and ownership on ${destination_path}"
  sudo chown -R root:wheel "$destination_path" ; success_or_not
  sudo chmod -R go-w "$destination_path" ; success_or_not

  report_end_phase_standard
  return 0
}

function is_semantic_version_arg1_at_least_arg2() {
  # is_semantic_version_arg1_at_least_arg2 ARG1 ARG2
  #
  # Returns 0 (success) iff (normalized ARG1) >= (normalized ARG2)
  # according to semantic version ordering.
  #
  # Normalization rules:
  #   - Strips a leading "v" if present
  #   - Removes everything from the first "-" or "+" onward
  #     e.g., "1.3-", "1.3-1", and "1.3+5" would each reduce to "1.3"
  #
  # Examples:
  #   is_semantic_version_arg1_at_least_arg2 "1"   "1.5"  → returns 1 (false)
  #   is_semantic_version_arg1_at_least_arg2 "1.5" "1.0"  → returns 0 (true)
  #   is_semantic_version_arg1_at_least_arg2 "2.2" "2.2"  → returns 0 (true)

  local arg1="$1"
  local arg2="$2"

  arg1="${arg1#v}"
  arg2="${arg2#v}"

  arg1="${arg1%%[-+]*}"
  arg2="${arg2%%[-+]*}"

  is-at-least "$arg2" "$arg1"
}

