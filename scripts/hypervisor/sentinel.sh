#!/usr/bin/env zsh

set -euo pipefail





function sentinel_of_the_hypervisor() {
  update_repo

}

function source_with_report() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  #
  # Defining this function here solves a chicken-or-egg problem: We’d like to use the helper 
  # safe_source(), but it hasn’t been sourced yet. The current function is not quite as full functional 
  # but will do for the initial sourcing of helpers.
  local file="$1"
  if source "$file"; then
    echo "Sourced: $file"
  else
    return "Failed to source: $file"
    return 1
  fi
}

function update_repo() {
  cd ~/.genomac-system
  git pull --recurse-submodules origin main
}
