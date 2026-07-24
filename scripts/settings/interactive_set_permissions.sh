#!/usr/bin/env zsh

function conditional_interactive_ensure_terminal_has_fda() {
  # Ensures that current terminal app has Full Disk Access, unless this has already been done earlier this session.
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$SESH_TERMINAL_FULL_DISK_ACCESS_HAS_BEEN_ASSURED" \
	  interactive_ensure_terminal_has_fda \
    "Skipping ensuring Full Disk Access for current terminal, because this has already been assured earlier this session."
    
  report_end_phase_standard
}
