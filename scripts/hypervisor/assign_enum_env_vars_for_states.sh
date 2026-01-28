#!/usr/bin/env zsh

# Establishes values for environment variables that act as enums corresponding
# to states.
#
# Assumes that export_and_report() has already been made available
#
# In the current implementation of state management:
# - each state corresponds to the existence of a file whose filename is of either form 
#   PERM_xxx.state or SESH_xxx.state, where xxx is a string.
# - the existence of a state’s file implies the state is true; the absence of a state’s file
#   implies the state is false.
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
# 			  - e.g., manual (i.e., interactive) authentication of an app or external service
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
# GenoMac-user and GenoMac-system each has is its own distinct set of states. These two sets of
# states are kept segregated by being stored in separate directories. Nothing about their names
# is sufficient to distinguish GenoMac-user states from GenoMac-system states.
# 	  	  
# The key of each state begins with either
# 	- `PERM_` for “permanent”
# 		- Such a `PERM_` key persists across sessions. It is reset (i.e., deleted) only
# 		  if an extraordinary circumstance arises that, after deliberation, is found to 
# 		  warrant the repetition of this otherwise-bootstrap step.
# 	- `SESH_` for “session”
# 		- is cleared/reset/deleted as the final step of each successful session
#
# States provide a mechanism such that the hypervisor script can be re-entered (for example,
# following an enforced logout) and be able to determine which steps can be skipped over 
# and where to pick up the remaining sequence.
# 		  
# The state mechanism is managed by the repository (i.e., GenoMac-system or GenoMac-user).
# Therefore the state mechanism doesn’t cover the earliest stages of the GenoMac-system
# or GenoMac-user processes that instruct/direct the user to achieve the local cloning
# of the repository.

PERM_GENOMAC_USER_HAS_BEEN_CLONED="PERM_genomac_user_has_been_cloned"
PERM_HOMEBREW_PATH_HAS_BEEN_ADJUSTED="PERM_homebrew_path_has_been_adjusted"
PERM_MAC_APP_STORE_IS_SIGNED_INTO="PERM_mac_app_store_is_signed_into"
PERM_MAC_NAMES_AND_LOGIN_WINDOW_MESSAGE_OBTAINED="PERM_Mac_names_and_login_window_message_obtained"
PERM_THIS_USER_IS_A_USER_CONFIGGER="PERM_this_user_is_a_user_configger"

SESH_REACHED_FINALITY="SESH_reached_finality"
SESH_SESSION_HAS_STARTED="SESH_session_has_started"

SESH_HOMEBREW_APPS_HAVE_BEEN_INSTALLED="SESH_homebrew_apps_have_been_installed"
SESH_NON_HOMEBREW_APPS_HAVE_BEEN_INSTALLED="SESH_non_homebrew_apps_have_been_installed"
SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES="SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES"
SESH_RESOURCES_HAVE_BEEN_INSTALLED="SESH_resources_have_been_installed"
SESH_SYSTEMWIDE_SETTINGS_HAVE_BEEN_IMPLEMENTED="SESH_systemwide_settings_have_been_implemented"

# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables corresponding to states."

export_and_report PERM_GENOMAC_USER_HAS_BEEN_CLONED
export_and_report PERM_HOMEBREW_PATH_HAS_BEEN_ADJUSTED
export_and_report PERM_MAC_APP_STORE_IS_SIGNED_INTO
export_and_report PERM_MAC_NAMES_AND_LOGIN_WINDOW_MESSAGE_OBTAINED
export_and_report PERM_THIS_USER_IS_A_USER_CONFIGGER

export_and_report SESH_REACHED_FINALITY
export_and_report SESH_HOMEBREW_APPS_HAVE_BEEN_INSTALLED
export_and_report SESH_NON_HOMEBREW_APPS_HAVE_BEEN_INSTALLED
export_and_report SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES
export_and_report SESH_RESOURCES_HAVE_BEEN_INSTALLED
export_and_report SESH_SESSION_HAS_STARTED
export_and_report SESH_SYSTEMWIDE_SETTINGS_HAVE_BEEN_IMPLEMENTED
