#!/usr/bin/env zsh

function conditional_interactive_ensure_terminal_has_fda() {
  # Template for a Zsh function in Project GenoMac
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$SESH_TERMINAL_FULL_DISK_ACCESS_HAS_BEEN_ASSURED" \
	  interactive_ensure_terminal_has_fda \
    "Skipping setting Full Disk Access for current terminal, because this has already been assured earlier this session."
    
  report_end_phase_standard
}
