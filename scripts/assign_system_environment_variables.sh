#!/usr/bin/env zsh

# Establishes values for environment variables used exclusively by GenoMac-system

# Intended to be sourced by scripts/0_initialize_me_second.sh

#############################################
#                  Aliases to intra-repository hierarchical structures
#
############### Local directory into which the GenoMac-system repo is cloned
# ~/.genomac-system
# Defined in GenoMac-shared/scripts/assign_common_environment_variables.sh
# GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"

############### ~/.genomac-system/homebrew
# Local directory that holds declarative Homebrew files
GMS_HOMEBREW="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/homebrew"

############### ~/.genomac-system/resources
# Local directory that holds resources (files or folders) needed for particular
# operations by GenoMac-system, typically resources to be installed at the system level
GMS_RESOURCES="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources"

# Specify the local directory that holds documentation files to display to the executing user
# ~/.genomac-system/resources/docs_to_display_to_user
GMS_DOCS_TO_DISPLAY="${GMS_RESOURCES}/docs_to_display_to_user"

############### ~/.genomac-system/scripts
# - Local directory that holds scripts: ~/.genomac-system/scripts
GMS_SCRIPTS="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/scripts"

# ~/.genomac-system/scripts/hypervisor
# - Local subdirectory of GMS_SCRIPTS that holds scripts specific to Hypervisor
GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor" 

# ~/.genomac-system/scripts/installations
GMS_INSTALL_SCRIPTS="${GMS_SCRIPTS}/installations"
GMS_HOMEBREW_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/homebrew"
GMS_NON_HOMEBREW_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/non_homebrew"
GMS_RESOURCE_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/of_resources"

# ~/.genomac-system/scripts/settings
GMS_SETTINGS_SCRIPTS="${GMS_SCRIPTS}/settings"

# ~/.genomac-system/scripts/user_scope
GMS_USER_SCOPE_SCRIPTS="${GMS_SCRIPTS}/user_scope"

############### ~/.genomac-system/utilities
# Holds narrow-focused scripts to be individually accessed by make recipes
GMS_UTILITIES="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/utilities"

###

report_action_taken "Export environment variables to be available in all subsequent shells."

export_and_report GMS_DOCS_TO_DISPLAY
export_and_report GMS_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_HOMEBREW
export_and_report GMS_HYPERVISOR_SCRIPTS
export_and_report GMS_INSTALL_SCRIPTS
export_and_report GMS_NON_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_RESOURCE_INSTALL_SCRIPTS
export_and_report GMS_RESOURCES
export_and_report GMS_SCRIPTS
export_and_report GMS_SETTINGS_SCRIPTS
export_and_report GMS_USER_SCOPE_SCRIPTS
export_and_report GMS_UTILITIES

