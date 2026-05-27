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
