#!/usr/bin/env zsh

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
