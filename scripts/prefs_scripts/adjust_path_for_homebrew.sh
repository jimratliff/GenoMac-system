#!/usr/bin/env zs

function conditionally_adjust_path_for_homebrew() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    --force-logout \
    "$PERM_HOMEBREW_PATH_HAS_BEEN_ADJUSTED" \
    adjust_path_for_homebrew \
    "Skipping adjusting PATH for Homebrew, because this was done in the past."

  report_end_phase_standard
}

function adjust_path_for_homebrew() {
  # (a) Modify systemwide PATH for Homebrew and (b) make man pages available to all users
  report_start_phase_standard

  keep_sudo_alive

  # Add Homebrew shellenv to /etc/zprofile (PATH, etc.)
  report_action_taken "Modifying global PATH to allow access to Homebrew-installed apps by all users"
  if ! sudo grep -q 'BEGIN HOMEBREW shellenv' /etc/zprofile 2>/dev/null; then
    sudo sh -c 'cat >>/etc/zprofile <<\EOF
# --- BEGIN HOMEBREW shellenv (system-wide) ---
if [ -x /opt/homebrew/bin/brew ]; then
eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# --- END HOMEBREW shellenv (system-wide) ---
EOF'
    fi ; success_or_not
  
  # Ensure man pages for all users (idempotent)
  report_action_taken "Making man pages available to all users"
  sudo mkdir -p /etc/manpaths.d
  printf "${HOMEBREW_PREFIX}/share/man\n" | sudo tee /etc/manpaths.d/homebrew >/dev/null ; success_or_not
  
  # Prime THIS shell so subsequent commands work
  report_action_taken "Priming shell… 🎬"
  eval "$(/opt/homebrew/bin/brew shellenv)" ; success_or_not

  report_action_taken "Systemwide adjustments have been completed to make important functionalities available to all users"

  report_end_phase_standard
}
