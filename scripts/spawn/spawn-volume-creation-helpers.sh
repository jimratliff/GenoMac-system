#!/usr/bin/env zsh

function create_and_encrypt_volume_on_container() {
  # Creates volume on container, encrypting it with passphrase referenced by a
  # 1Password item
  
  report_start_phase_standard
  local volume_name="${1? missing volume name}"
  local op_item_key="${2? missing 1Password item}"
  local container_name="${3? missing container name}"

  local passphrase
  local op_vault

  # If volume already exists on container, do nothing
  if $volume_exists_on_container "$volume_name" "$container_name"; then
    report "Volume “$volume_name” already exists in container “$container_name”; Moving on…"
    report_warning "I can’t guarantee that volume “$volume_name” is encrypted by the desired passphrase."
    report_end_phase_standard
    return 0
  fi
  
  op_vault=$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION
  passphrase="$(read_1password_item_password "$op_vault" "$op_item_key")"
  # Optional volume-level encryption of an APFS volume from inception using the 
  # `diskutil apfs addVolume -passphrase` verb.
  printf '%s' "$passphrase" | diskutil apfs addVolume "$container_name" APFS "$volume_name" -stdinpassphrase

  report_end_phase_standard
}

function volume_exists_on_container() {
  # Returns 0 if volume already exists on given container
  
  report_start_phase_standard
  local volume_name="${1? missing volume name}"
  local container_name="${2? missing container name}"

  if diskutil apfs list "$container_name" | grep -Fq "Name: ${volume_name} "; then
    report "Volume “$volume_name” already exists in container “$container_name”; Moving on…"
    report_warning "I can’t guarantee that volume “$volume_name” is encrypted by the desired passphrase."
    report_end_phase_standard
    return 0
  fi
  report_end_phase_standard
  return 1
}

function volume_name_is_mounted() {
  # Tests whether a non-startup volume with the given volume name is currently mounted.
  #
  # Returns:
  #   0 if mounted at /Volumes/$volume_name
  #   1 otherwise
  #
  # Does not handle the startup volume, which is normally mounted at /, and which must be
  # mounted in order to run any script.
  #
  # Usage:
  #   if volume_name_is_mounted "Personal"; then
  #     print "Personal is mounted"
  #   else
  #     print "Personal is not mounted"
  #   fi
  
  report_start_phase_standard

  local volume_name="${1:?missing/empty volume_name}"
  local mount_point="/Volumes/${volume_name}"

  [[ -d "${mount_point}" ]] || return 1
  mount | grep -Fq " on ${mount_point} "
  report_end_phase_standard
}

function volume_name_is_startup_volume_signifier() {
  # Returns 0 if supplied volume name is $STARTUP_VOLUME_SIGNIFIER, otherwise returns 1.
  report_start_phase_standard
  local volume_name="${1:?missing volume_name}"
  if [[ "$volume_name" == "$STARTUP_VOLUME_SIGNIFIER" ]]; then
    report_end_phase_standard
    return 0
  fi
  report_end_phase_standard
  return 1
}

function determine_startup_container() {
  # Determines the container of the startup volume.
  # This container will be used for all subsequent new volumes for user home directories
  
  report_start_phase_standard
  local container_ref

  if ! container_ref="$(
    "$PLISTBUDDY_PATH" -c 'Print :APFSContainerReference' /dev/stdin \
        <<<"$(diskutil info -plist /)"
  )"; then
    report_fail "Failed to determine APFS container for startup volume."
    return 1
  fi

  # Normalize to form diskutil apfs addVolume accepts comfortably.
  # If the plist already includes /dev/, leave it alone.
  container_ref="/dev/${container_ref#/dev/}"

  report "Container of startup volume is: ${container_ref}"

  # “Return” value
  print -- "$container_ref"

  report_end_phase_standard
}
