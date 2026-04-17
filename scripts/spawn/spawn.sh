#!/usr/bin/env zsh

set -euo pipefail

function create_user_accounts_for_this_Mac() {
  # Creates specific user accounts for this Mac.
  # When a user to be created is specified to reside (i.e., its home directory inhabits) a volume
  #   that doesn’t currently exist, that volume is created.
  #
  # It’s assumed that this process is being executed by USER_CONFIGURER, which already exists, as does
  #   a "vanilla" account. Thus, the users being created are anticipated to be the third and subsequent
  #   users.
  #
  # Each user to be created is specified by:
  # - "name"
  #   - a string, e.g., "Betty")
  # - "uid"
  #   - the user’s ID, in the range 510–999, which macOS uses to distinguish users (rather than by user name)
  #   - (Project GenoMac excludes IDs 501–509 here, even though they are legit user IDs, in order to prevent
  #     conflicts with preexisting users.)
  # - "class"
  #   - a string key, e.g., "simple_admin", "implementor", "unsullied", "personal", "work", "auxiliary"
  #   - Determines (a) the user’s password and (b) the volume on which the user’s home directory resides.
  # - "avatar"
  #   - ############### WIP
  #
  # This function assumes that:
  # - GenoMac-system has been cloned locally to GENOMAC_SYSTEM_LOCAL_DIRECTORY (~/.genomac-system).
  # - scripts/0_initialize_me_first.sh has been sourced
  #   - This sources (a) helpers and cross-repo environment variables from GenoMac-shared and
  #     (b) repo-specific environment variables.
  
  report_start_phase_standard

  keep_sudo_alive

  # ############### TODO WORK IN PROGRESS

  report_end_phase_standard
}
