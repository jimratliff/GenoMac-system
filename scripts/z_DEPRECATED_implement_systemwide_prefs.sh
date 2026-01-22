#!/usr/bin/env zsh

# Implements system-wide settings (i.e., that affect all users)

# Fail early on unset variables or command failure
set -euo pipefail

safe_source "${GMS_PREFS_SCRIPTS}/set_initial_systemwide_settings.sh"

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
dump_accumulated_warnings_failures


