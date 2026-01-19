#!/usr/bin/env zs

function ensure_terminal_has_fda() {
  # Run at the beginning of a terminal session to try to ensure the currently running terminal
  # app has Full Disk Access (FDA) permission.
  #
  # If the terminal app does *not* have FDA, the Settings » Privacy & Security » Full Disk Access
  # panel is opened, this terminal app should already be pre-populated (but un-enabled) on the 
  # list of apps, so the user can simply flip the switch for this app.
  #
  # The reason this terminal app will be pre-populated on the FDA list is: The current script tests
  # whether the current terminal app has FDA by attempting to query a restricted location.
  # If the app doesn’t have FDA, this query is sufficient for macOS to add this app to that list.

  # Query a restricted location
  if ! ls ~/Library/Mail &>/dev/null; then
    # The currently running terminal app does *not* have FDA
    if [[ -t 0 ]]; then
      # The session is interactive
      open_privacy_panel_for_full_disk_permissions
    else
      # The session is not interactive
      report_warning "Warning: Terminal lacks FDA and no interactive session to fix it"
      return 1
    fi
  fi
}
