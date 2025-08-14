#!/bin/zsh

# Clone GenoMac-dotfiles repo to GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR, GENOMAC_DOTFILES_REPO_URL, 
# and GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY)
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################
function clone_genomac_dotfiles_repo() {
  report_start_phase_standard

  local local_cloning_dir="$GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY"
  local repo_url="$GENOMAC_DOTFILES_REPO_URL"

  report_action_taken "Ensuring target directory exists: $local_cloning_dir"
  mkdir -p "$local_cloning_dir"; success_or_not

  report_action_taken "Changing directory to: $local_cloning_dir"
  cd "$local_cloning_dir"; success_or_not

  report_action_taken "Cloning repo: $repo_url"
  git clone "$repo_url" .; success_or_not

  report_end_phase_standard
}

function main() {
  clone_genomac_dotfiles_repo
}

main
