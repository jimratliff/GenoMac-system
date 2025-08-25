#!/bin/zsh

# Installs fonts.

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR).
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Font-related scripts should be placed in GenoMac-system/scripts/font-scripts

# Currently only Fira Code Nerdfont is installed. To add additional fonts would require
# some refactoring; it’s not as simple as adding a line to a Brewfile. 😉

# Specify the directory in which the file(s) containing the font-related 
# functions called by this script lives.
# E.g., the function `install_fira_code_nerd_font_systemwide` is supplied by a file 
# `install_fira_code_nerd_font_systemwide.sh`. Assuming `install_fira_code_nerd_font_systemwide.sh` 
# resides at the same level as this script:
# PREFS_FONT_FUNCTIONS_DIR="${this_script_dir}"
PREFS_FONT_FUNCTIONS_DIR="${this_script_dir}/font_scripts"

# Print assigned paths for diagnostic purposes
printf "\n📂 Path diagnostics:\n"
printf "this_script_dir:              %s\n" "$this_script_dir"
printf "GENOMAC_HELPER_DIR: %s\n" "$GENOMAC_HELPER_DIR"
printf "PREFS_FONT_FUNCTIONS_DIR:  %s\n\n" "$PREFS_FONT_FUNCTIONS_DIR"

# Source function(s)
source "${PREFS_FONT_FUNCTIONS_DIR}/install_fira_code_nerd_font_systemwide.sh"

############################## BEGIN SCRIPT PROPER ##############################
function install_fonts() {
  report_start_phase_standard

  # Installs Fira Code Nerdfont
  install_fira_code_nerd_font_systemwide

  report_end_phase_standard

}

function main() {
  install_fonts
}

main
