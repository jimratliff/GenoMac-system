#!/usr/bin/env zsh

# Establishes values for environment variables used exclusively by GenoMac-system
#
# Intended to be sourced by scripts/0_initialize_me_first.sh
#
# Assumes that export_and_report() has already been made available
#
# See also environment_variables_for_state_enums_script.sh

# Local directory into which the GenoMac-system repo is cloned
# ~/.genomac-system
# Defined in GenoMac-shared/scripts/assign_common_environment_variables.sh
# GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"

#############################################
#                  Aliases to intra-repository hierarchical structures
#
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

# ~/.genomac-system/scripts/spawn
GMS_USER_SPAWNING_SCRIPTS="${GMS_SCRIPTS}/spawn"

############### ~/.genomac-system/utilities
# Holds narrow-focused scripts to be individually accessed by make recipes
GMS_UTILITIES="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/utilities"

############### 1Password-related
# Name of 1Password vault that stores items related to user creation
ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION="GenoMac-user-creation"

# Name of 1Password item that stores the JSON configuration mapping user-class to (a) passwords and (b) volumes
ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG="GenoMac-system_user_spawn_config_json"

# Name of 1Password item that stores the list of users to create
ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE="GenoMac-system_specs_of_users_to_create"

###

############### Related to spawning new user accounts

# Specify the local directory in which user login pictures are stored to be
# accessed by GenoMac-system when it creates user accounts.
GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY="$HOME/.genomac-system-login-pictures-for-user-creation"

# Directory (relative to current volume) in which all user home directories reside
# NOTE: The prefixing `/` is part of the string. This simplifies constructing the path in the case that the
#       home directory is located at the root of the volume.
USER_DIRECTORY_CONTAINER_WITHIN_VOLUME="/Users"

###

report_action_taken "Export environment variables to be available in all subsequent shells."

export_and_report ONEPASSWORD_ITEM_NAME_SPECS_OF_USERS_TO_CREATE
export_and_report ONEPASSWORD_ITEM_NAME_USER_SPAWN_CONFIG
export_and_report ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
export_and_report GMS_DOCS_TO_DISPLAY
export_and_report GMS_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_HOMEBREW
export_and_report GMS_HYPERVISOR_SCRIPTS
export_and_report GMS_INSTALL_SCRIPTS
export_and_report GMS_LOGIN_PICTURES_FOR_USER_CREATION_DIRECTORY
export_and_report GMS_NON_HOMEBREW_INSTALL_SCRIPTS
export_and_report GMS_RESOURCE_INSTALL_SCRIPTS
export_and_report GMS_RESOURCES
export_and_report GMS_SCRIPTS
export_and_report GMS_SETTINGS_SCRIPTS
export_and_report GMS_USER_SCOPE_SCRIPTS
export_and_report GMS_USER_SPAWNING_SCRIPTS
export_and_report GMS_UTILITIES
export_and_report STARTUP_VOLUME_SIGNIFIER
export_and_report USER_DIRECTORY_CONTAINER_WITHIN_VOLUME

