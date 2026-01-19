#!/usr/bin/env zsh

# Establishes values for environment variables that act as enums corresponding
# to states.
#
# Assumes that export_and_report() has already been made available
#
# There are two kinds of steps:
# - Bootstrap
# 	- Typically executed once per given Mac
# 		- Examples
# 			- a setting that is initialized to a default value but where it is anticipated that
# 			  the user may override that setting and would not want their override to itself
# 			  be overridden by re-running the original configuration script
# 			  - e.g., a Dock lineup, toolbar configurations of particular apps
# 			- an action that, despite being idempotent, you wouldn’t want to repeat
# 			  because the action is time consuming or otherwise costly
# 			  - e.g., setting the default browser (I don’t know why this is so time consuming, 
# 			    but it is!)
# 			  - e.g., registering a QuickLook plugin (costly because launching and then quitting 
# 			    an app takes time)
# 			- a manual configuration that can’t be automated (and therefore is too expensive for
# 			  thoughtless repetition, even if doing so would be idempotent)
# 			  - e.g., authentication of an app or external service
# 			  - e.g., implementing a setting that isn’t exposed to scripting (e.g., granting 
# 			    full-disk access to an app)
# - Maintenance
# 	- Must be idempotent
# 	- Repeated periodically either (a) to enforce previously set settings or (b) to reflect
# 	  recent changes
# 	  - Examples:
# 	  	- stowing dotfiles
# 	  	- `defaults write` commands, where you want to continually enforce the choices 
# 	  	  specified by GenoMac-user, even if the user has deviated from those
#
# GenoMac-user and GenoMac-system each is its own distinct set of states. These two sets of
# states are kept segregated by being stored in separate directories. Nothing about their names
# is sufficient to distinguish GenoMac-user states from GenoMac-system states.
# 	  	  
# The key of each state begins with either
# 	- `PERM_` for “permanent”
# 		- Such a `PERM_` key persists across sessions. It is reset (i.e., deleted) only
# 		  if an extraordinary circumstance arises that, after deliberation, is found to 
# 		  warrant the repetition of this otherwise-bootstrap step.
# 	- `SESH_` for “session”
# 		- is cleared/reset/deleted as the final step of each successful session (or possibly
# 		  at the beginning of each “new” session, though it’s not clear how to easily 
# 		  determine that—without determining that the current SESH states take you all the 
# 		  way to the end)
# 		- `SESH_` states provide a mechanism such that the hypervisor script can be re-entered
# 			(for example, following an enforced logout) and be able to determine which steps
# 			can be skipped over and where to pick up the remaining sequence.
# 		  
# The state mechanism is managed by the repository (i.e., GenoMac-system or GenoMac-user).
# Therefore the state mechanism doesn’t cover the earliest stages of the GenoMac-system
# or GenoMac-user processes that instruct/direct the user to achieve the local cloning
# of the repository.

set -euo pipefail

# Just some examples as a template
# PERM_1PASSWORD_HAS_BEEN_AUTHENTICATED="PERM_1password_has_been_authenticated"

PERM_HOMEBREW_PATH_HAS_BEEN_ADJUSTED="PERM_homebrew_path_has_been_adjusted"

# SESH_BASIC_IDEMPOTENT_SETTINGS_HAVE_BEEN_IMPLEMENTED="SESH_basic_idempotent_settings_have_been_implemented"
# SESH_REACHED_FINALITY="SESH_reached_finality"
# SESH_SESSION_HAS_STARTED="SESH_session_has_started"

# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables corresponding to states."

# export_and_report PERM_1PASSWORD_HAS_BEEN_AUTHENTICATED
export_and_report PERM_HOMEBREW_PATH_HAS_BEEN_ADJUSTED

# export_and_report SESH_BASIC_IDEMPOTENT_SETTINGS_HAVE_BEEN_IMPLEMENTED
# export_and_report SESH_REACHED_FINALITY
# export_and_report SESH_SESSION_HAS_STARTED
