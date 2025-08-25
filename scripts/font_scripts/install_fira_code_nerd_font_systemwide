# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please source `install_fira_code_nerd_font_systemwide.sh` first."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################

function install_fira_code_nerd_font_systemwide() {
  # Installs the Fira Code Nerdfont for all users (i.e., systemwide)

  report_start_phase_standard

  local font_name="FiraCode Nerd Font"
  local font_dir="/Library/Fonts/GenoMac-FiraCode"
  local zip_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  local temp_dir; temp_dir="$(mktemp -d)"
  local exit_code=0

  report_action_taken "Download latest version of ${font_name}"
  if curl -fsSL "$zip_url" -o "$temp_dir/FiraCode.zip"; then
    report_success "Downloaded zip archive of ${font_name} successfully"
  else
    report_fail "Failed to download zip archive of ${font_name}"
    rm -rf "$temp_dir"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Unzip ${font_name} archive to temporary directory (${temp_dir})"
  if unzip -q "$temp_dir/FiraCode.zip" -d "$temp_dir/unzipped"; then
    report_success "Unzipped ${font_name} archive"
  else
    report_fail "Failed to unzip archive"
    rm -rf "$temp_dir"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Ensure destination folder exists: $font_dir"
  if sudo mkdir -p "$font_dir"; then
    report_success "Created destination directory (if missing)"
  else
    report_fail "Failed to create destination directory"
    rm -rf "$temp_dir"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Copy .ttf font files to $font_dir (idempotent)"

  keep_sudo_alive

  local copied=0
  local font_file
  for font_file in "$temp_dir/unzipped"/*.ttf; do
    local dest="$font_dir/$(basename "$font_file")"
    if [[ ! -e "$dest" ]] || ! cmp -s "$font_file" "$dest"; then
      sudo cp -f "$font_file" "$dest" && copied=1
    fi
  done
  if [[ $copied -eq 1 ]]; then
    report_success "Font files copied or updated"
  else
    report_fail "No font files needed copying (already up to date)"
  fi

  report_action_taken "Set proper ownership and permissions"
  if sudo chown root:wheel "$font_dir"/*.ttf && sudo chmod 644 "$font_dir"/*.ttf; then
    report_success "Permissions corrected"
  else
    report_fail "Failed to set permissions"
    rm -rf "$temp_dir"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Clean up temporary files"
  rm -rf "$temp_dir" ; success_or_not

  report_end_phase_standard
  return $exit_code
}
