#!/usr/bin/env zsh

function list_File_Vault_enabled_users() {
  # List File Vault–enabled users
  report_start_phase_standard
  report "The following users are enabled to unlock File Vault on this startup volume:${NEWLINE}"
  sudo fdesetup list | cut -d ',' -f 1
  report_end_phase_standard
}
