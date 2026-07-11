#!/usr/bin/env zsh

function list_FileVault_enabled_users() {
  # Reports the short names of all users enabled to unlock FileVault.

  report_start_phase_standard

  local filevault_enabled_users
  filevault_enabled_users="$(sudo fdesetup list | cut -d ',' -f 1)"

  _report \
    --alert \
    --message "The following users are enabled to unlock FileVault on this startup volume:${NEWLINE}${filevault_enabled_users}"

  report_end_phase_standard
}
