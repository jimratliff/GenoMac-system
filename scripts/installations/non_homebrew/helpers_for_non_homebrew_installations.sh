#!/bin/zsh

function warn_if_github_latest_release_differs_from_pinned() {
  local display_name="$1"
  local repo_slug="$2"
  local pinned_tag="$3"

  local latest_tag=""

  report_action_taken "Checking GitHub latest release tag for ${display_name}"
  if latest_tag="$(gh release view --repo "$repo_slug" --json tagName -q .tagName 2>/dev/null)"; then
    success_or_not

    if [[ -n "$latest_tag" && "$latest_tag" != "$pinned_tag" ]]; then
      report_warning "GitHub latest release tag for ${display_name} is ${latest_tag}; you are pinned to ${pinned_tag}. To upgrade, review the release, update the pinned tag/version, and run Hypervisor again."
    fi
  else
    success_or_not
    report_warning "Could not check GitHub latest release tag for ${display_name}; continuing with pinned ${pinned_tag}."
  fi
}
