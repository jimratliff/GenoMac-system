#!/usr/bin/env zsh

function conditionally_install_officetime() {
  # Installs OfficeTime unless if has already been installed.
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_OFFICETIME_HAS_BEEN_INSTALLED" \
    install_officetime \
    "Skipping installing OfficeTime, because this was done in the past."
  
  report_end_phase_standard
}

function install_officetime() {
  # Installs OfficeTime from its website. No version checking.
  report_start_phase_standard

  local download_url="https://officetime.net/downloads/v3/OfficeTime.dmg"
  local temporary_directory
  local dmg_path
  local mount_point
  local -i mounted=0
  local -i cleanup_failed=0

  temporary_directory="$(mktemp -d)" || return 1
  dmg_path="${temporary_directory}/OfficeTime.dmg"
  mount_point="${temporary_directory}/mount"

  {
    report_action_taken_to_log "Download OfficeTime from: ${download_url}"

    curl --fail --location --silent --show-error \
         --retry 3 \
         --connect-timeout 15 \
         --output "$dmg_path" \
         "$download_url" || return 1

    mkdir "$mount_point" || return 1

    report_to_log "Mount OfficeTime disk image."

    hdiutil attach "$dmg_path" \
        -mountpoint "$mount_point" \
        -readonly -nobrowse -noautoopen || return 1
    mounted=1

    if [[ ! -d "${mount_point}/OfficeTime.app" ]]; then
      report_fail "OfficeTime.app was not found in the disk image."
      return 1
    fi

    report_action_taken_to_log "Install OfficeTime into /Applications."

    sudo ditto \
        "${mount_point}/OfficeTime.app" \
        "/Applications/OfficeTime.app" || return 1
  } always {
    if (( mounted )); then
      report_to_log "Detach OfficeTime disk image."
      hdiutil detach "$mount_point" || cleanup_failed=1
    fi

    if (( cleanup_failed )); then
      report_warning "Could not detach disk image of OfficeTime app; retained: ${temporary_directory}"
    else
      report_to_log "Remove temporary OfficeTime installer directory."
      rm -rf "$temporary_directory" || cleanup_failed=1
    fi
  }

  report_end_phase_standard
}
