#!/usr/bin/env zsh

set -euo pipefail

function update_repo() {
  cd ~/.genomac-system
  git pull --recurse-submodules origin main
}

function sentinel_of_the_hypervisor() {
  update_repo

}
