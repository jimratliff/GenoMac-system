#!/usr/bin/env zs

function get_full_disk_access_for_Terminal() {
  tell_Terminal_to_require_full_disk_access
  sleep 2
  open "$PRIVACY_SECURITY_PANEL_URL_FULL_DISK"

}
