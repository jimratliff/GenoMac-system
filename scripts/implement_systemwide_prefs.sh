#!/usr/bin/env zsh

# Implements system-wide settings (i.e., that affect all users)

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR).
# Assumes that assign_environment_variables.sh is in same directory as the
# current script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Specify the directory in which the file(s) containing the preferences-related 
# functions called by this script lives.
# E.g., the function `get_loginwindow_message` is supplied by a file 
# `get_loginwindow_message.sh`. Assuming `get_loginwindow_message.sh` 
# resides at the same level as this script:
# PREFS_FUNCTIONS_DIR="${this_script_dir}"
PREFS_FUNCTIONS_DIR="${this_script_dir}/prefs_scripts"

# Print assigned paths for diagnostic purposes
printf "\n📂 Path diagnostics:\n"
printf "this_script_dir:              %s\n" "$this_script_dir"
printf "GENOMAC_HELPER_DIR: %s\n" "$GENOMAC_HELPER_DIR"
printf "PREFS_FUNCTIONS_DIR:  %s\n\n" "$PREFS_FUNCTIONS_DIR"


source "${PREFS_FUNCTIONS_DIR}/set_initial_systemwide_settings.sh"

############################## BEGIN SCRIPT PROPER #############################
report_start_phase 'Begin the systemwide-settings phase'

# Set initial system-wide settings (requires sudo)
set_initial_systemwide_settings

# Kill each app affected by `defaults` commands in the prior functions
# In this case, none of these might be necessary, but killing these two won’t hurt.
# (App-killing deferred here to avoid redundantly killing the same app multiple times.)
report_action_taken "Force quit all apps/processes whose settings we just changed"
apps_to_kill=(
  "SystemUIServer"
  "cfprefsd"
)

for app_to_kill in "${apps_to_kill[@]}"; do
  report_about_to_kill_app "$app_to_kill"
  killall "$app_to_kill" 2>/dev/null || true
  success_or_not
done

report "It’s possible that some settings won’t take effect until after you logout or restart."
report_end_phase 'Completed: the preference-setting phase of the bootstrapping process'


