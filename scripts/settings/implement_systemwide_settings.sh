#!/usr/bin/env zsh

function conditionally_implement_systemwide_settings() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_SYSTEMWIDE_SETTINGS_HAVE_BEEN_IMPLEMENTED" \
    implement_systemwide_settings \
    "Skipping implementation of system-wide settings, because these were implemented earlier this session."
  
  report_end_phase_standard
}

function implement_systemwide_settings() {
  # Makes system-wide settings, requiring sudo, to be run from USER_CONFIGURER.
  
  report_start_phase_standard
  
  report_action_taken "Begin commands that require 'sudo'"
  keep_sudo_alive
  
  # Disable auto-boot when opening the lid or connecting to power on Apple Silicon laptop
  # Howard Oakley, “How to change lid behaviour on MacBook Air and Pro,” Eclectic Light Company, February 3, 2025
  # https://eclecticlight.co/2025/02/03/how-to-change-lid-behaviour-on-macbook-air-and-pro/
  report_action_taken "Disable auto-boot when opening the lid or connecting to power on Apple Silicon laptop"
  sudo nvram BootPreference=%00 ; success_or_not
  
  ############### Configure application firewall
  report_action_taken "Configure application firewall"
  report_adjust_setting "1 of 2: Enable application firewall"
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on ; success_or_not
  report_adjust_setting "2 of 2: Enable Stealth Mode"
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on ; success_or_not
  ###
  
  ############### Configure system-wide settings controlling software-update behavior
  report_action_taken "Implement system-wide settings controlling how macOS and MAS-app software updates occur"
  
  report_adjust_setting "Do automatically check for updates (both macOS and MAS apps)"
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true ; success_or_not
  
  report_adjust_setting "Download updates when available"
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true ; success_or_not
  
  report_adjust_setting "Do NOT automatically update macOS"
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false ; success_or_not
  
  report_adjust_setting "Do automatically update applications from Mac App Store"
  sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true ; success_or_not
  ###
  
  # Display additional information on login window
  report_adjust_setting "Display additional info (IP address, hostname, OS version) when clicking on the clock digits of the login window"
  # Requires restart.
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName ; success_or_not

  # Enable Touch ID authentication for sudo
  # See https://dev.to/siddhantkcode/enable-touch-id-authentication-for-sudo-on-macos-sonoma-14x-4d28
  # As of macOS Sonoma, the settings can be added to a separate file /etc/pam.d/sudo_local, which isn’t
  # overwritten during updates, allowing Touch ID to remain enabled for sudo commands consistently.
  report_action_taken "Enable Touch ID authentication for sudo"
  sed -n -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local ; success_or_not
  
  report_end_phase_standard

}
