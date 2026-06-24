#!/bin/zsh

############### DEPRECATION WARNING: These appear not to be used

function gh_is_authenticated() {
  # Returns 0 if gh is authenticated; otherwise, returns 1
  local return_value
  report_start_phase_standard
  conditionally_test_for_gh_availability
  conditionally_test_for_gh_authentication
  if test_genomac_system_state "$SESH_GH_IS_AUTHENTICATED"; then
    return_value=0
  else
    return_value=1
  fi
  report_end_phase_standard
  return "$return_value"
}

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
  # Prints "0" to stdout if gh is available (though not necessarily authenticated); prints "1" otherwise.
  report_start_phase_standard
  if ! command -v gh >/dev/null 2>&1; then
    report_warning "gh unavailable. This is unexpected, because gh should be installed by Homebrew."
    print -- "1"
  else
    print -- "0"
  fi
  report_end_phase_standard
  return 0
}
  
function gh_authentication_indicator() {
  # Prints "0" to stdout if gh is authenticated; prints "1" otherwise.
  report_start_phase_standard
  if ! gh auth status >/dev/null 2>&1; then
    report_warning "gh isn’t authenticated. This is normal if the user hasn’t been set up to authenticate with GitHub yet."
    print -- "1"
  else
    print -- "0"
  fi
  report_end_phase_standard
  return 0
}


