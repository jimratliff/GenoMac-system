#!/bin/zsh

function install_utiluti() {
  # Installs utiluti from scriptingosx
  #
  # Here we *do* know the pkg id: com.scriptingosx.utiluti  [oai_citation:0‡Scripting OS X](https://scriptingosx.com/?utm_source=chatgpt.com)
  # Confirm the pkg_filename on the v1.3 release page.
  
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
