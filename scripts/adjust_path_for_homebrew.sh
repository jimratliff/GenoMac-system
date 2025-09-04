#!/bin/zsh

# (a) Modify PATH for Homebrew and (b) modify fpath for Homebrew’s Zsh

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR, GENOMAC_USER_REPO_URL, 
# and GENOMAC_USER_LOCAL_DIRECTORY)
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER #############################
function adjust_path_for_homebrew() {
  report_start_phase_standard

  # Guard clause: Fail fast if Homebrew not installed
  if [ ! -x /opt/homebrew/bin/brew ]; then
    report_fail "ERROR: Homebrew not found at /opt/homebrew/bin/brew; Install Homebrew first!"
    return 1
  fi
  
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
  
# # Add Homebrew fpath setup to /etc/zshenv (completions)
# report_action_taken "Modifying global fpath to allow access to Homebrew’s Zsh’s completions by all users"
# if ! sudo grep -q 'BEGIN HOMEBREW fpath' /etc/zshenv 2>/dev/null; then
# sudo sh -c 'cat >>/etc/zshenv <<\EOF
# # --- BEGIN HOMEBREW fpath (system-wide) ---
# if [ -x /opt/homebrew/bin/brew ]; then
# typeset -U fpath
# fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
# fi
# # --- END HOMEBREW fpath (system-wide) ---
# EOF'
# fi ; success_or_not
  
  # Ensure man pages for all users (idempotent)
  report_action_taken "Making man pages available to all users"
  sudo mkdir -p /etc/manpaths.d
  printf '/opt/homebrew/share/man\n' | sudo tee /etc/manpaths.d/homebrew >/dev/null ; success_or_not
  
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
  sleep 3  # Give user time to read the message

  # Graceful logout using familiar system behavior
  osascript -e 'tell application "System Events" to log out'
}

function main() {
  adjust_path_for_homebrew
}

main
