#!/bin/zsh

function install_tool_via_package_from_github() {
  # Download and install a GitHub-hosted macOS installer package (.pkg) whose
  # payload is a *command-line tool or utility*, not an .app bundle, and manage
  # versioning via pkgutil when possible.
  #
  # Usage:
  #   install_tool_via_package_from_github [-f] tool_name repo_slug pinned_version pkg_filename [pkg_id] [binary_path]
  #
  # Options:
  #   -f  Force update: reinstall even if version/presence checks would skip or no package 
  #				is specified from which the version of the currently installed tool can be determined.
  #
  # Arguments:
  #   1: tool_name       – human-readable name, e.g. "default-browser"
  #   2: repo_slug       – "owner/repo", e.g. "macadmins/default-browser"
  #   3: pinned_version  – Git tag, e.g. "v1.0.18"
  #                        (we derive pkg version "1.0.18" by stripping a leading "v")
  #   4: pkg_filename    – exact .pkg filename in that release
  #   5: pkg_id          – optional pkgutil package id (e.g. "com.scriptingosx.utiluti")
  #   6: binary_path     – optional path of installed binary to verify

  report_start_phase_standard

  # Parse options
  local force_update=false

  OPTIND=1
  local opt
  while getopts ":f" opt; do
    case "$opt" in
      f) force_update=true ;;
      *)
        report_fail "Unknown option -${OPTARG} for install_tool_via_package_from_github"
        ;;
    esac
  done
  shift $((OPTIND - 1))

  # Positional args
  local tool_name="${1:-}"
  local repo_slug="${2:-}"
  local pinned_version="${3:-}"
  local pkg_filename="${4:-}"
  local pkg_id="${5:-}"
  local binary_path="${6:-}"

  if [[ -z "$tool_name" || -z "$repo_slug" || -z "$pinned_version" || -z "$pkg_filename" ]]; then
    report_fail "Usage: install_tool_via_package_from_github [-f] tool_name repo_slug pinned_version pkg_filename [pkg_id] [binary_path]"
  fi

  # Derived versions/URLs
  local pinned_tag="$pinned_version"
  local pinned_pkg_version="${pinned_version#v}"

  local installed_version=""

  # Version-aware idempotence when pkg_id is known
  if [[ "$force_update" != true ]] && [[ -n "$pkg_id" ]] && pkgutil --pkg-info "$pkg_id" >/dev/null 2>&1; then

    installed_version="$(
      pkgutil --pkg-info "$pkg_id" 2>/dev/null \
        | awk -F': ' '/^version:/ {print $2}'
    )"

    if [[ -n "$installed_version" ]]; then
      # If installed >= pinned, do nothing. (Includes equality.)
      if is_semantic_version_arg1_at_least_arg2 "$installed_version" "$pinned_pkg_version"; then
        if [[ -n "$binary_path" ]]; then
          if [[ -x "$binary_path" ]]; then
            report_action_taken "${tool_name} already at version ${installed_version}; binary present at ${binary_path}; skipping re-install"
            success_or_not
            report_end_phase_standard
            return 0
          else
            report_warning "${tool_name} receipt at version ${installed_version} exists, but binary is missing at ${binary_path}; reinstalling"
            success_or_not
            # fall through to download + install
          fi
        else
          report_action_taken "${tool_name} already at version ${installed_version}; skipping re-install"
          success_or_not
          report_end_phase_standard
          return 0
        fi
      else
        report_action_taken "Upgrading ${tool_name} from ${installed_version} to ${pinned_pkg_version}"
        success_or_not
        # fall through to download + install
      fi
    fi

  # Fallback idempotence when pkg_id is unknown
  elif [[ "$force_update" != true ]] && [[ -z "$pkg_id" && -n "$binary_path" && -x "$binary_path" ]]; then
    report_warning "${tool_name} is present at ${binary_path}, but no pkg_id was provided, so version cannot be verified; skipping re-install"
    success_or_not
    report_end_phase_standard
    return 0
  fi

  # If forcing update, say so (helps explain why we reinstall)
  if [[ "$force_update" == true ]]; then
    report_action_taken "Force update requested for ${tool_name}; reinstalling from pinned ${pinned_tag}"
    success_or_not
  fi

  ###########################################################################
  # Download + install
  ###########################################################################
  local temp_dir
  temp_dir="$(mktemp -d)"

  local pkg_url="https://github.com/${repo_slug}/releases/download/${pinned_tag}/${pkg_filename}"
  local pkg_path="${temp_dir}/${pkg_filename}"

  report_action_taken "Downloading ${tool_name} ${pinned_version} from ${pkg_url}"
  curl -fsSL "$pkg_url" -o "$pkg_path" ; success_or_not

  report_action_taken "Installing ${tool_name} from ${pkg_path}"
  sudo installer -pkg "$pkg_path" -target / ; success_or_not

  # Optional verification by binary path
  if [[ -n "$binary_path" ]]; then
    if [[ -x "$binary_path" ]]; then
      report_action_taken "Verified ${tool_name} binary at ${binary_path}"
      true ; success_or_not
    else
      report_fail "Expected ${tool_name} binary at ${binary_path}, but it was neither found nor executable after purported installation."
      report_end_phase_standard
      return 1
    fi
  fi

  # Optional: check for newer GitHub release (best-effort)
  report_action_taken "Checking for newer ${tool_name} release on GitHub"
  local latest_tag
  latest_tag="$(gh release view --repo "$repo_slug" --json tagName -q .tagName 2>/dev/null || true)"
  success_or_not

  if [[ -n "$latest_tag" && "$latest_tag" != "$pinned_tag" ]]; then
    report_warning "GitHub reports a different latest release for ${tool_name}: ${latest_tag}. You are pinned to ${pinned_tag}."
  fi

  # Clean up temp dir
  rm -rf "$temp_dir"

  report_end_phase_standard
  return 0
}
