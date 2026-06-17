#!/usr/bin/env zsh
#
# Installs a fixed “pinned version.” An update from the publisher necessitates a manual intervention.
#
# If a newer version (than $HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_STRING) is released, and the decision
# is made to adopt it:
# - Update $HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_STRING to equal the new-version string
# - Add a date-timed migration command to hypervisor(), for example:
#   - migrate_system_states "MIGRATION_ID_2026_06_17_1527" --delete "$PERM_HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_HAS_BEEN_INSTALLED"
#   - This will cause all systems that had already installed a pinned version to forget that they had done so,
#     allowing them to install the new pinned version the next time Hypervisor is run.

HIARCS_CHESS_EXPLORER_PRO_DOWNLOAD_PAGE_URL="https://www.hiarcs.com/mac-chess-explorer-pro-download.html"
HIARCS_CHESS_EXPLORER_PRO_PACKAGE_URL_STEM="https://www.hiarcs.com/xa/HIARCS-Chess-Explorer-Pro-Installer-v"
HIARCS_CHESS_EXPLORER_PRO_PACKAGE_URL_SUFFIX=".pkg"
HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_STRING="1.5.2"

function conditionally_install_hiarcs_chess_explorer_pro() {
  # Installs HIARCS Chess Explorer Pro unless the pinned version has already been installed.
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_HAS_BEEN_INSTALLED" \
    install_hiarcs_chess_explorer_pro \
    "Skipping installing HIARCS Chess Explorer Pro, because this was done in the past."
    
  warn_if_newer_hiarcs_chess_explorer_pro_version_is_available
  
  report_end_phase_standard
}

function install_hiarcs_chess_explorer_pro() {
  # Installs HIARCS Chess Explorer Pro from its website.
  report_start_phase_standard
  local pinned_version="${HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_STRING}"

  local package_url
  local package_filename
  local package_path
  local temporary_directory

  package_url="${HIARCS_CHESS_EXPLORER_PRO_PACKAGE_URL_STEM}${pinned_version}${HIARCS_CHESS_EXPLORER_PRO_PACKAGE_URL_SUFFIX}"
  package_filename="HIARCS-Chess-Explorer-Pro-Installer-v${pinned_version}.pkg"

  temporary_directory="$(mktemp -d)"
  package_path="${temporary_directory}/${package_filename}"

  report_action_taken_to_log "Download HIARCS Chess Explorer Pro v${pinned_version} package from: ${package_url}"

  curl --fail --location --silent --show-error \
       --retry 3 \
       --connect-timeout 15 \
       --output "$package_path" \
       "$package_url"

  report_action_taken_to_log "Install HIARCS Chess Explorer Pro v${pinned_version} package."
  sudo installer -pkg "$package_path" -target /

  report_action_taken_to_log "Remove temporary HIARCS installer directory."
  rm -rf "$temporary_directory"
  
  report_end_phase_standard
}

function warn_if_newer_hiarcs_chess_explorer_pro_version_is_available() {
  # Warns if the HIARCS download page contains a parseable semantic version greater than the pinned version.
  #
  # This does not auto-update the pinned version. Developer intervention is required.

  report_start_phase_standard

  local pinned_version="${HIARCS_CHESS_EXPLORER_PRO_PINNED_VERSION_STRING}"
  local download_page_url="${HIARCS_CHESS_EXPLORER_PRO_DOWNLOAD_PAGE_URL}"

  local candidate_version

  local -a discovered_versions

  discovered_versions=("${(@f)$(get_hiarcs_chess_explorer_pro_download_versions "$download_page_url")}")

  if (( ${#discovered_versions[@]} == 0 )); then
    report_warning "No parseable HIARCS Chess Explorer Pro package versions were found on the download page.${NEWLINE}The page structure or URL naming convention may have changed."
  fi

  for candidate_version in "${discovered_versions[@]}"; do
    if ! is_semantic_version_arg1_at_least_arg2 "$pinned_version" "$candidate_version"; then
      report_warning "HIARCS Chess Explorer Pro may have a newer version available: discovered v${candidate_version}, but pinned version is v${pinned_version}.${NEWLINE}Manual developer intervention is required before updating the pinned version."
    fi
  done

  report_end_phase_standard
}

function get_hiarcs_chess_explorer_pro_download_versions() {
  # Prints numeric semantic versions found in expected direct HIARCS .pkg URLs.
  #
  # Examples:
  #   ...Installer-v1.5.pkg       -> 1.5
  #   ...Installer-v1.5.2.pkg     -> 1.5.2
  #   ...Installer-v1.5.1a.pkg    -> 1.5.1

  report_start_phase_standard

  local download_page_url="${1:?MISSING download_page_url}"

  curl --fail --location --silent --show-error \
       --retry 3 \
       --connect-timeout 15 \
       "$download_page_url" |
    perl -nE '
      while (m{https://www\.hiarcs\.com/xa/HIARCS-Chess-Explorer-Pro-Installer-v([0-9]+(?:\.[0-9]+){1,2})[^/"]*?\.pkg}g) {
        say $1;
      }
    ' |
    sort -u

  report_end_phase_standard
}
