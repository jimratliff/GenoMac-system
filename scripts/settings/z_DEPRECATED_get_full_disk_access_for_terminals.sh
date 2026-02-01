#!/usr/bin/env zsh

function ensure_terminal_has_fda() {
  # Run at the beginning of a terminal session to try to ensure the currently running terminal
  # app has Full Disk Access (FDA) permission.
  #
  # If the terminal app does *not* have FDA, the Settings » Privacy & Security » Full Disk Access
  # panel is opened. This terminal app should already appear (but un-enabled) on the 
  # list of apps, so the user can simply flip the switch for this app.
  #
  # NOTE: This does *not* use a state variable, because FDA is required for each terminal application
  #       e.g., Terminal, iTerm, Warp, etc. It would require too much complexity to (a) determine which
  #       terminal application was currently running and (b) whether it had already been tested for FDA.
  #
  # Note: FDA changes require restarting the terminal app to take effect.

  report_start_phase_standard
  report_action_taken "Testing currently running terminal app for Full Disk Access"

  # Query a restricted location to test FDA (and as side effect, add terminal app to FDA list)
  if ls ~/Library/Mail &>/dev/null; then
    report_success "Terminal already has Full Disk Access"
    report_end_phase_standard
    return 0
  fi

  # The currently running terminal app does *not* have FDA
  # macOS will have added the terminal app to the FDA list (but un-enabled)

  if [[ ! -t 0 ]]; then
    report_warning "Warning: Terminal lacks Full Disk Access and no interactive session to fix it"
    report_end_phase_standard
    return 1
  fi

  open_privacy_panel_for_full_disk_permissions
  launch_app_and_prompt_user_to_act \
    --no-app \
    --show-doc "${GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY}/full_disk_access_how_to_configure.md" \
    "Follow the instructions in the Quick Look window to grant the current terminal app Full Disk Access"

  report_end_phase_standard
}
