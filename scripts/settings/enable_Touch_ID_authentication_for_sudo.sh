#!/usr/bin/env zsh

function enable_Touch_ID_authentication_for_sudo() {
  # Enable Touch ID authentication for sudo
  # See https://dev.to/siddhantkcode/enable-touch-id-authentication-for-sudo-on-macos-sonoma-14x-4d28
  # As of macOS Sonoma, the settings can be added to a separate file /etc/pam.d/sudo_local, which isn’t
  # overwritten during updates, allowing Touch ID to remain enabled for sudo commands consistently.
  report_start_phase_standard
  report_action_taken "Enable Touch ID authentication for sudo"
  sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local ; success_or_not
  report_end_phase_standard
}
