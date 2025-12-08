#!/bin/zsh

# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please ensure helpers.sh has been loaded before sourcing helper_install_package_from_github.sh."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Fail early on unset variables or command failure
set -euo pipefail

############################## GENERIC HELPER ##############################

# Downloads a macOS package installer from a GitHub repo and installs the package’s payload.

# install_package_from_github
#
# Arguments:
#   1: tool_name       – human-readable name, e.g. "default-browser"
#   2: repo_slug       – "owner/repo", e.g. "macadmins/default-browser"
#   3: pinned_version  – Git tag, e.g. "v1.0.18"
#   4: pkg_filename    – exact .pkg filename in that release
#                        (e.g. "default-browser-1.0.18.pkg")
#   5: pkg_id          – optional pkgutil package id (e.g. "com.scriptingosx.utiluti")
#   6: binary_path     – optional path of installed binary to verify (e.g. "/opt/macadmins/bin/default-browser")
#
# Idempotence:
#   - If pkg_id is provided and pkgutil finds it, we skip.
#   - Else if binary_path exists and is executable, we skip.
#
function install_package_from_github() {

  report_start_phase_standard

  local tool_name="$1"
  local repo_slug="$2"
  local pinned_version="$3"
  local pkg_filename="$4"
  local pkg_id="${5:-}"
  local binary_path="${6:-}"

  # Idempotence: bail out early if we already have it.
  if [[ -n "$pkg_id" ]]; then
    if pkgutil --pkg-info "$pkg_id" >/dev/null 2>&1; then
      report_action_taken "${tool_name} already installed (pkgid: ${pkg_id}); skipping re-install"
      success_or_not
      return 0
    fi
  fi

  if [[ -n "$binary_path" && -x "$binary_path" ]]; then
    report_action_taken "${tool_name} already installed at ${binary_path}; skipping re-install"
    success_or_not
    return 0
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  # No trap to avoid fighting with other scripts; just clean up explicitly.

  local pkg_url="https://github.com/${repo_slug}/releases/download/${pinned_version}/${pkg_filename}"
  local pkg_path="${temp_dir}/${pkg_filename}"

  report_action_taken "Downloading ${tool_name} ${pinned_version} from ${pkg_url}"
  curl -fsSL "$pkg_url" -o "$pkg_path" ; success_or_not

  report_action_taken "Installing ${tool_name} from ${pkg_path}"
  sudo installer -pkg "$pkg_path" -target / ; success_or_not

  # Optional verification by binary path
  if [[ -n "$binary_path" ]]; then
    if [[ -x "$binary_path" ]]; then
      report_action_taken "Verified ${tool_name} binary at ${binary_path}"
      success_or_not
    else
      report_warning "Expected ${tool_name} binary at ${binary_path}, but it was not found or not executable."
    fi
  fi

  # Optional: check for newer GitHub release (best-effort)
  report_action_taken "Checking for newer ${tool_name} release on GitHub"
  local latest_tag
  latest_tag="$(gh release view --repo "$repo_slug" --json tagName -q .tagName 2>/dev/null || true)"
  success_or_not

  if [[ -n "$latest_tag" && "$latest_tag" != "$pinned_version" ]]; then
    report_warning "A newer version of ${tool_name} is available: ${latest_tag}. You are pinned to ${pinned_version}."
  fi

  # Clean up temp dir
  rm -rf "$temp_dir"

  report_end_phase_standard

  return 0
}

