#!/usr/bin/env zsh

function install_bettertouchtool() {
  report_start_phase_standard

  conditionally_force_install_bundle_from_downloaded_zip \
    "$SESH_BETTERTOUCHTOOL_FORCE_REPLACE_INSTALL" \
    "$BETTERTOUCHTOOL_APP_DOWNLOAD_LINK" \
    "BetterTouchTool.app" \
    "$BUNDLE_ID_BETTERTOUCHTOOL"

  report_end_phase_standard
}
