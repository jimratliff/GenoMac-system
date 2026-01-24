#!/usr/bin/env zsh

# Establishes values for environment variables used exclusively by GenoMac-system

# Intended to be sourced by scripts/0_initialize_me_second.sh

############### Aliases to intra-repository hierarchical structures

# Aliases defined in scripts/0_initialize_me_first.sh
# - Local directory into which the GenoMac-system repo is cloned
#   GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system" 
# - Local directory that holds scripts
#   GMS_SCRIPTS="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/scripts"
# - Local subdirectory of GMS_SCRIPTS that holds scripts specific to Hypervisor
#   GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor" 

# Local directory that holds declarative Homebrew files
GMS_HOMEBREW="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/homebrew"

# Local directory that holds resources (files or folders) needed for particular
# operations by GenoMac-system, typically resources to be installed at the system level
GMS_RESOURCES="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources"

# Specify the local directory that holds documentation files to display to the executing user
GMS_DOCS_TO_DISPLAY="${GMS_RESOURCES}/docs_to_display_to_user"

############### Subdirectories of /scripts
# Hypervisor scripts (defined in 0_initialize_me_first.sh)
# GMS_HYPERVISOR_SCRIPTS="${GMS_SCRIPTS}/hypervisor"

# Install scripts
GMS_INSTALL_SCRIPTS="${GMS_SCRIPTS}/installations"
GMS_HOMEBREW_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/homebrew"
GMS_NON_HOMEBREW_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/non_homebrew"
GMS_RESOURCE_INSTALL_SCRIPTS="${GMS_INSTALL_SCRIPTS}/of_resources"

# Settings scripts
GMS_SETTINGS_SCRIPTS="${GMS_SCRIPTS}/settings"

# User-scope scripts
GMS_USER_SCOPE_SCRIPTS="${GMS_SCRIPTS}/user_scope"

###

# Environment variables to support the Hypervisor
GMS_HYPERVISOR_MAKE_COMMAND_STRING="make run-hypervisor"
local message="To restart, re-execute ${GMS_HYPERVISOR_MAKE_COMMAND_STRING} and we’ll pick up where we left off."
GMS_HYPERVISOR_HOW_TO_RESTART_STRING="${message}"

report_action_taken "Export environment variables to be available in all subsequent shells."

export_and_report GMS_DOCS_TO_DISPLAY
export_and_report GMS_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_HOMEBREW
export_and_report GMS_HYPERVISOR_HOW_TO_RESTART_STRING
export_and_report GMS_HYPERVISOR_MAKE_COMMAND_STRING
export_and_report GMS_INSTALL_SCRIPTS
export_and_report GMS_NON_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_RESOURCE_INSTALL_SCRIPTS
export_and_report GMS_RESOURCES
export_and_report GMS_SETTINGS_SCRIPTS
export_and_report GMS_USER_SCOPE_SCRIPTS

