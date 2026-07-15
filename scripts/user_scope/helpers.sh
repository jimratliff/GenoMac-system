#!/usr/bin/env zsh

function list_FileVault_enabled_users() {
  # Reports the short names of all users enabled to unlock FileVault.

  report_start_phase_standard

  local filevault_enabled_users
  filevault_enabled_users="$(sudo fdesetup list | cut -d ',' -f 1)"

  _report \
    --alert \
    --message "The following users are enabled to unlock FileVault on this startup volume:${NEWLINE}${filevault_enabled_users}"

  report_end_phase_standard
}

function set_user_picture() {
  # Sets the account picture for an existing local user.
  #
  # Usage:
  #   set_user_picture short_name /absolute/path/to/image

  report_start_phase_standard

  local short_name="${1:?MISSING short_name}"
  local picture_path="${2:?MISSING picture_path}"
  local user_record="/Users/${short_name}"

  if [[ "${picture_path}" != /* ]]; then
    report_fail "ERROR: User-picture path must be absolute: ${picture_path}"
    return 1
  fi

  if [[ ! -f "${picture_path}" ]]; then
    report_fail "ERROR: User-picture file does not exist: ${picture_path}"
    return 1
  fi

  if ! dscl . -read "${user_record}" RecordName &>/dev/null; then
    report_fail "ERROR: No local user exists with short name: ${short_name}"
    return 1
  fi

  # An embedded JPEGPhoto ordinarily overrides the path stored in Picture.
  if sudo dscl . -read "${user_record}" JPEGPhoto &>/dev/null; then
    sudo dscl . -delete "${user_record}" JPEGPhoto
  fi

  sudo dscl . -create "${user_record}" Picture "${picture_path}"

  report_end_phase_standard
}
