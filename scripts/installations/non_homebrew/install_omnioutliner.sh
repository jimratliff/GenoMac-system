#!/usr/bin/env zsh

function install_omnioutliner() {
  # Installs OmniOutliner 5 from .zip archive stored in Dropbox into /Applications unless (a) app already present
  # or state $SESH_OMNIOUTLINER_FORCE_REPLACE_INSTALL is present.
  #
  # This version is no longer available for download from the Mac App Store.
  #
  # Expects the .zip archive of the OmniOutliner app to be stored at $OMNIOUTLINER_5_BINARY

  report_start_phase_standard

  conditionally_force_install_bundle_from_local_zip \
    "$SESH_OMNIOUTLINER_FORCE_REPLACE_INSTALL" \
    "$OMNIOUTLINER_5_BINARY" \
    "$OMNIOUTLINER_5_APP_FILENAME" \
    "$BUNDLE_ID_OMNIOUTLINER_5"

  report_end_phase_standard
}
