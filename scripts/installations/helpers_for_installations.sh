#!/bin/zsh

# is-at-least is builtin to zsh but must be explicitly loaded before called.
autoload -Uz is-at-least

function warn_if_github_latest_release_differs_from_pinned() {
  local display_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"

  local latest_tag=""

  report_start_phase_standard

  abort_if_gh_not_installed_or_not_on_path

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

function install_bundle_from_local_zip() {
  # Installs a locally sourced, zipped macOS app into /Applications (by default).
  # Usage:
  #   install_bundle_from_local_zip [--force-replace] ZIP BUNDLE_NAME BUNDLE_ID [DESTINATION]
  #
  # - --force-replace may appear anywhere among the arguments.
  # - DESTINATION defaults to /Applications.
  # - BUNDLE_NAME is the bundle filename, e.g. "OmniOutliner.app".
  # - An existing DESTINATION/BUNDLE_NAME is left alone unless --force-replace
  #   is supplied. The extracted bundle must match both name and bundle ID.
  #
  # No version checks or permanent-state tracking. Requires an existing ZIP parent
  # directory; a missing or unreadable ZIP is an error when installation is needed.
  # Relies on the caller's set -euo pipefail; call directly, not in an if/|| test.
  report_start_phase_standard

  local force_replace=false
  local argument
  local -a positional_arguments=()

  for argument in "$@"; do
    case "$argument" in
      --force-replace) force_replace=true ;;
      *) positional_arguments+=("$argument") ;;
    esac
  done
  set -- "${positional_arguments[@]}"

  local path_of_local_zip="${1:-}"
  local bundle_name="${2:-}"
  local bundle_id="${3:-}"
  local destination_dir="${4:-/Applications}"

  local temp_dir=""
  local candidate
  local candidate_id
  local source_bundle
  local destination_path="${destination_dir}/${bundle_name}"

  local -a matching_bundles=()

  if (( $# < 3 || $# > 4 )) || [[ -z "$path_of_local_zip" || -z "$bundle_name" || -z "$bundle_id" ]]; then
    report_fail "Expected ZIP path, bundle filename, bundle ID, and optional destination directory."
    report_end_phase_standard
    return 1
  fi

  if [[ "$bundle_name" == */* || "$bundle_name" == . || "$bundle_name" == .. ]]; then
    report_fail "Expected a bundle filename without directory components: ${bundle_name}"
    return 1
  fi

  if [[ -d "$destination_path" ]]; then
    if [[ "$force_replace" == false ]]; then
      report_to_log "${destination_path} already exists (and --force-replace not set); skipping installation"
      report_end_phase_standard
      return 0
    else
      report_to_log "${destination_path} already exists but --force-replace; continuing installation"
    fi
  else
    report_to_log "${destination_path} doesn’t exist; continuing installation"
  fi

  ############### BEGIN: TEMPORARY GUARDRAIL UNTIL FURTHER TESTING OBVIATES THE NEED
  local confirmation_question
  confirmation_question="I’m about to install bundle ${bundle_id}${NEWLINE}Do you want to continue?"
  if ! get_yes_no_answer_to_question "$confirmation_question"; then
    report_fail "I thought that bundle ${bundle_id} needed to be installed, but you disagreed. One of us is wrong."
    return 1
  fi
  ############### END: TEMPORARY GUARDRAIL UNTIL FURTHER TESTING OBVIATES THE NEED

  if [[ ! -d "${path_of_local_zip:h}" ]]; then
    report_fail "ZIP parent directory does not exist: ${path_of_local_zip:h}"
    return 1
  fi

  if [[ ! -f "$path_of_local_zip" || ! -r "$path_of_local_zip" ]]; then
    report_fail "ZIP is missing or unreadable: ${path_of_local_zip}"
    return 1
  fi

  if [[ ! -d "$destination_dir" ]]; then
    report_fail "Destination directory does not exist: ${destination_dir}"
    return 1
  fi

  temp_dir="$(mktemp -d)"
  {
    report_action_taken "Extracting ${path_of_local_zip}"
    /usr/bin/ditto -x -k "$path_of_local_zip" "$temp_dir"

    # Locate the bundle to install within the extracted ZIP by matching its bundle ID.
    # Search recursively because the ZIP may place the bundle inside a containing folder.
    # Require exactly one match, then verify its filename matches bundle_name.
    while IFS= read -r -d '' candidate; do
      candidate_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$candidate" 2>/dev/null)" || continue
      if [[ "$candidate_id" == "$bundle_id" ]]; then
        matching_bundles+=("${candidate:h:h}")
      fi
    done < <(/usr/bin/find "$temp_dir" -type f -path '*/Contents/Info.plist' -print0)

    if (( ${#matching_bundles} != 1 )); then
      report_fail "Expected one bundle with ID ${bundle_id}; found ${#matching_bundles}."
      return 1
    fi

    source_bundle="${matching_bundles[1]}"
    if [[ "${source_bundle:t}" != "$bundle_name" ]]; then
      report_fail "Expected bundle filename ${bundle_name}; found ${source_bundle:t}."
      return 1
    fi

    report_action_taken_to_log "If running, I will quit bundle ${bundle_id}"
    quit_app_by_bundle_id_if_running "$bundle_id"

    report_action_taken_to_log "Replacing ${destination_path} from local ZIP"
    sudo rm -rf -- "$destination_path"
    sudo /usr/bin/ditto "$source_bundle" "$destination_path"
    sudo chown -R root:wheel "$destination_path"
    sudo chmod -R go-w "$destination_path"
  } always {
    rm -rf -- "$temp_dir"
    report_end_phase_standard
  }
  return 0
}

function conditionally_force_install_bundle_from_local_zip() {
  # Takes a state followed by arguments for install_bundle_from_local_zip. If state is present,
  # execute install_bundle_from_local_zip with --force-replace option; otherwise, execute
  # install_bundle_from_local_zip without --force-replace

  report_start_phase_standard

  local state_for_force_installation="${1:?MISSING state_for_force_installation}"
  shift

  if test_genomac_system_state "$state_for_force_installation"; then
    install_bundle_from_local_zip --force-replace "$@"
  else
    install_bundle_from_local_zip "$@"
  fi

  # Relies on set -euo pipefail: a failed install must not reach state deletion.
  # Call this wrapper directly, not in an if/|| test.
  # A successful skip also counts as success.
  delete_genomac_system_state "$state_for_force_installation"

  report_end_phase_standard
}

function is_semantic_version_arg1_greater_than_arg2() {
  # Returns 0 iff ARG1 > ARG2 according to semantic version ordering. Otherwise returns 1.
  #
  # Depends on:
  #   is_semantic_version_arg1_at_least_arg2

  local arg1="${1:?MISSING arg1}"
  local arg2="${2:?MISSING arg2}"

  if is_semantic_version_arg1_at_least_arg2 "$arg1" "$arg2" \
    && ! is_semantic_version_arg1_at_least_arg2 "$arg2" "$arg1"; then
    return 0
  fi

  return 1
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

  local arg1="${1:?MISSING arg1}"
  local arg2="${2:?MISSING arg2}"

  arg1="${arg1#v}"
  arg2="${arg2#v}"

  arg1="${arg1%%[-+]*}"
  arg2="${arg2%%[-+]*}"

  is-at-least "$arg2" "$arg1"
}
