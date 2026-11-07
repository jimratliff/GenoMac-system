#!/usr/bin/env zsh

function install_proton_drive() {
  # Installs Proton Drive app from .zip archive stored in Dropbox into /Applications unless (a) app already present
  # or state $SESH_PROTON_DRIVE_FORCE_REPLACE_INSTALL is present.
  #
  # Homebrew installation is avoided because of a (hopefully temporary) problem with Homebrew
  # installations of Proton Drive not working reliably.
  #
  # Expects the .zip archive of the Proton Drive app to be stored at $PROTON_DRIVE_BINARY

  report_start_phase_standard

  conditionally_force_install_bundle_from_local_zip \
    "$SESH_PROTON_DRIVE_FORCE_REPLACE_INSTALL" \
    "$PROTON_DRIVE_BINARY" \
    "$PROTON_DRIVE_APP_FILENAME" \
    "$BUNDLE_ID_PROTON_DRIVE"

  report_end_phase_standard
}
