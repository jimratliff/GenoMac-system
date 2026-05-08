#!/usr/bin/env zsh

function conditionally_install_rosetta() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_ROSETTA_PREFERENCE_HAS_BEEN_ASCERTAINED" \
    interactive_ask_whether_to_install_rosetta \
    "Skipping asking about Rosetta, because this question has been answered in the past."

  run_if_system_state \
    "$PERM_ROSETTA_SHOULD_BE_INSTALLED" \
    install_rosetta_if_not_already_installed \
    "Skipping installing Rosetta 2 because its installation isn’t desired."

  report_end_phase_standard
}

function install_rosetta_if_not_already_installed() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_ROSETTA_HAS_BEEN_INSTALLED" \
    install_rosetta
    "Skipping installing Rosetta 2 because it’s already been installed."

  report_end_phase_standard
}

function install_rosetta() {
  report_action_taken "Installing Rosetta 2"
  sudo softwareupdate --install-rosetta --agree-to-license
  success_or_not
}

function interactive_ask_whether_to_install_rosetta() {
  report_start_phase_standard

  report "Rosetta 2 is required for some apps, e.g., Eagle Filer."
  set_system_state_based_on_yes_no \
    "$PERM_ROSETTA_SHOULD_BE_INSTALLED" \
    "Should Rosetta 2 be installed?"

  report_end_phase_standard
}

