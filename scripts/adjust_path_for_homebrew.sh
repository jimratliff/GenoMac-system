#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

source "${HOME}/.genomac-user/scripts/0_initialize_me.sh"

function adjust_path_for_homebrew() {
  # (a) Modify systemwide PATH for Homebrew and (b) make man pages available to all users
  report_start_phase_standard

  # Guard clause: Fail fast if Homebrew not installed
  ensure_homebrew_is_installed
  
  # Main logic - we know Homebrew exists from here on

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

  report_action_taken "PATH/fpath changes complete. Logging out to apply system-wide changes..."
  echo ""
  echo "ℹ️  You will be logged out automatically to apply the new PATH settings."
  echo "   After logging back in, continue with the next bootstrap step."
  echo ""
  echo "ℹ️  As part of that process, you will see a permission dialog asking if Terminal can control System Events."
  echo "   Click 'OK' to allow the automatic logout to proceed."
  echo "   This permission is only needed during initial bootstrap."
  echo ""

  force_user_logout
}

function main() {
  adjust_path_for_homebrew
}

main
