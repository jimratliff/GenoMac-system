#!/bin/zsh

# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please ensure helpers.sh has been loaded before sourcing install_tool_via_package_from_github.sh."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Fail early on unset variables or command failure
set -euo pipefail

# 2) utiluti (scriptingosx)
#
# Here we *do* know the pkg id: com.scriptingosx.utiluti  [oai_citation:0‡Scripting OS X](https://scriptingosx.com/?utm_source=chatgpt.com)
# Again, confirm the pkg_filename on the v1.3 release page.
#
function install_utiluti() {
  report_start_phase_standard

  local tool_name="utiluti"
  local repo_slug="scriptingosx/utiluti"
  local pinned_version="v1.3"
  local pkg_filename="utiluti-1.3.pkg"
  local pkg_id="com.scriptingosx.utiluti"
  local binary_path="/usr/local/bin/utiluti"

  install_tool_via_package_from_github \
    "$tool_name" \
    "$repo_slug" \
    "$pinned_version" \
    "$pkg_filename" \
    "$pkg_id" \
    "$binary_path"

  report_end_phase_standard

}
