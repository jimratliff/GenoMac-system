#!/usr/bin/env zsh

function conditionally_ask_and_set_verbosity_preference() {
  # Asks and sets user’s verbose-output preference, if not already asked this session.
  report_start_phase_standard
  run_if_system_has_not_done \
    "$SESH_Q_ASKED_VERBOSITY" \
	  ask_and_set_verbosity_preference \
    "Skipping asking about verbosity, because this has already been answered this session."
  report_end_phase_standard
}
