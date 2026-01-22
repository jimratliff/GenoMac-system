#!/bin/zsh

############### TODO WIP! Being refactored from GenoMac-user to GenoMac-system

function interactive_ask_initial_questions() {

  # Ask questions to the executing user that will guide the remainder of the Hypervisor process.
  # Typically, the answer to each true/false question depends only on the particular Mac,
  # not on the particular session.
  # Therefore, we ask these questions only once, the first time the user’s preferences are set
  # by GenoMac-user.

  report_start_phase_standard

  local prompt

  prompt="Does this user want to see, on the desktop, the built-in and external drives?"
  set_system_state_based_on_yes_no "$PERM_FINDER_SHOW_DRIVES_ON_DESKTOP" "$prompt"

  prompt="Will this user want to SSH authenticate GitHub using 1Password"
  set_system_state_based_on_yes_no "$PERM_1PASSWORD_USER_WANTS_TO_CONFIGURE_SSH_AGENT" "$prompt"

  prompt="Will this user sync preferences via Dropbox?"
  set_system_state_based_on_yes_no "$PERM_DROPBOX_USER_WANTS_IT" "$prompt"

  prompt="Will this user want to configure Microsoft Word?"
  set_system_state_based_on_yes_no "$PERM_MICROSOFT_WORD_USER_WANTS_IT" "$prompt"

  report_end_phase_standard

}
