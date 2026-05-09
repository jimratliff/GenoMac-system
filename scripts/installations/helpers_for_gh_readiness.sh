#!/bin/zsh

function conditionally_test_for_gh_availability() {
  report_start_phase_standard
  run_if_system_has_not_done \
    "$SESH_GH_AVAILABILITY_HAS_BEEN_ASCERTAINED" \
    set_state_based_on_gh_availability \
    "Skipping testing gh availability, because its availability has been ascertained earlier this session."
  report_end_phase_standard
}

function conditionally_test_for_gh_authentication() {
  report_start_phase_standard
  run_if_system_has_not_done \
    "$SESH_GH_AUTHENTICATION_HAS_BEEN_ASCERTAINED" \
    set_state_based_on_gh_authentication \
    "Skipping testing gh authentication, because its authentication has been ascertained earlier this session."
  report_end_phase_standard
}

function set_state_based_on_gh_availability() {
  determine_system_state_based_on_value "$SESH_GH_IS_AVAILABLE" "$(gh_availability_indicator)"
}

function set_state_based_on_gh_authentication() {
  determine_system_state_based_on_value "$SESH_GH_IS_AUTHENTICATED" "$(gh_authentication_indicator)"
}

function gh_availability_indicator(){
  # Returns 0 if gh is available (though not necessarily authenticated); returns 1 otherwise.
  report_start_phase_standard
  if ! command -v gh >/dev/null 2>&1; then
    print -- "1"
  else
    print -- "0"
  fi
  report_end_phase_standard
  return 0
}
  
function gh_authentication_indicator() {
  # Returns 0 if gh is authenticated; returns 1 otherwise.
  report_start_phase_standard
  if ! gh auth status >/dev/null 2>&1; then
    print -- "1"
  else
    print -- "0"
  fi
  report_end_phase_standard
  return 0
}


