#!/usr/bin/env zsh

function conditionally_interactive_get_Mac_names_and_login_window_message() {
  # If not previously obtained, asks user for computer names and login-window text.
  # If these were previously obtained, check computername to see whether it’s become mangled. If so, unmangle it.
  report_start_phase_standard

  if test_genomac_system_state "${PERM_MAC_NAMES_AND_LOGIN_WINDOW_MESSAGE_OBTAINED}"; then
    report_action_taken "Skipping asking for computer names and login-window text, because these were obtained in the past."
    fix_mangled_computername_if_necessary
  
  else
    interactive_get_Mac_names
    interactive_get_loginwindow_message
    # Sets this state so the user won’t be asked again to supply answers to these questions
    set_genomac_system_state "${PERM_MAC_NAMES_AND_LOGIN_WINDOW_MESSAGE_OBTAINED}"
  fi

  report_end_phase_standard
}

function interactive_get_Mac_names() {
  # Get and optionally set Mac computer names
  #
  # - Display current ComputerName to user, offering opportunity to change it.
  #   - If ComputerName has been “mangled” with a ' (nnn)' suffix (e.g., 'MyComputerName (5)'), strip that
  #     ' (nnn)' suffix, and alert user that this has occurred.
  #   - Offer the user the chance to change ComputerName.
  #     - This choice is offered both when ComputerName was not mangled and when it was mangled.
  #     - If user opts to change ComputerName, any leading/trailing whitespace characters are removed from the new name
  #       before assigning the new value to ComputerName.
  # - Compute new value for LocalHostName and assign it to LocalHostName.
  #   - This occurs regardless of whether ComputerName is changed or remains the same.
  #   - The new value for LocalHostName is computed from ComputerName by normalizing/sanitizing it by the sequence:
  #     - replace all whitespace with hyphens
  #     - remove every character that is neither an alphanumeric nor a hyphen
  #     - strip all leading/trailing hyphens (which removes all original characters that were leading/trailing whitespace)
  # - Do not assign any value to HostName
  
  report_start_phase_standard
  report_action_taken "Get and optionally set Mac ComputerName and LocalHostName"
  
  # Get current ComputerName
  current_name=$(sudo systemsetup -getcomputername 2>/dev/null | sed 's/^Computer Name: //')
  report "Current ComputerName: \"$current_name\""
  
  # Assume name is clean unless proven otherwise
  final_name_is_dirty=false

  # If current_name ends with ' (###)', clean it
  if final_name=$(mangled_computername_was_unmangled "$current_name"); then
    report_warning "ComputerName appears to have been auto-mangled. I have unmangled it: \"$final_name\""
    final_name_is_dirty=true
  fi
  
  # Ask whether to change the ComputerName
  if get_yes_no_answer_to_question "Would you like to change the ComputerName?"; then
    final_name=$(get_confirmed_answer_to_question "Enter desired ComputerName:")
    final_name_is_dirty=true
  else
    final_name="$current_name"
    report_action_taken "Keeping existing ComputerName."
  fi
  
  # Final assignment, if needed
  if [[ "$final_name_is_dirty" == true ]]; then
    report_action_taken "Assigning ComputerName to $final_name"
    sudo systemsetup -setcomputername "$final_name" 2> >(grep -v '### Error:-99' >&2); success_or_not
  fi

  set_localhostname_from_computername "${final_name}"
  
  # Display final names
  echo ""
  printf "Final name settings:\n"
  printf "ComputerName:   %s\n" "$(sudo scutil --get ComputerName 2>/dev/null || echo "(not set)")"
  printf "LocalHostName:  %s\n" "$(sudo scutil --get LocalHostName 2>/dev/null || echo "(not set)")"
  printf "HostName:       %s\n" "$(sudo scutil --get HostName 2>/dev/null || echo "(not set)")"
  
  report_end_phase_standard
}

function mangled_computername_was_unmangled() {
  # Takes a ComputerName, returns it with any ' (###)' suffix stripped.
  # Sets return code: 0 if mangled (was fixed), 1 if clean (unchanged).
  local name="$1"
  
  if echo "$name" | grep -qE ' \([0-9]+\)$'; then
    echo "$name" | sed -E 's/ \([0-9]+\)$//'
    return 0  # Was mangled
  fi
  
  echo "$name"
  return 1  # Was clean
}

function fix_mangled_computername_if_necessary() {
  # Check computername for mangling, fixing when necessary and then set localhostname.
  # This is a standalone, noninteractive version of interactive_get_Mac_names.
  report_start_phase_standard
  
  local current_name=$(sudo systemsetup -getcomputername 2>/dev/null | sed 's/^Computer Name: //')
  local fixed_name
  
  if fixed_name=$(mangled_computername_was_unmangled "$current_name"); then
    report_warning "ComputerName was auto-mangled. Fixing to: \"$fixed_name\""
    sudo systemsetup -setcomputername "$fixed_name" 2> >(grep -v '### Error:-99' >&2); success_or_not
    set_localhostname_from_computername "${fixed_name}"
  fi

  report_end_phase_standard
}

function sanitize_localhostname() {
  # Takes a name, returns it sanitized for use as LocalHostName:
  # - Replace all whitespace with hyphens
  # - Remove all but alphanumerics and hyphens
  # - Remove leading/trailing hyphens
  local name="$1"
  
  echo "$name" \
    | tr '[:space:]' '-' \
    | tr -cd '[:alnum:]-' \
    | sed 's/^-*//;s/-*$//'
}

function set_localhostname_from_computername() {
  # Derives LocalHostName from ComputerName and assigns it
  local computername="$1"
  local sanitized=$(sanitize_localhostname "$computername")
  
  report_action_taken "Setting LocalHostName: \"$sanitized\""
  sudo scutil --set LocalHostName "$sanitized"; success_or_not
}

function interactive_get_loginwindow_message() {
  # Get login-window message
  # Displays any preexisting login-window message
  # Asks user to supply new text, keep existing, or clear it.
  
  report_start_phase_standard
  report_action_taken "Set login-window message"

  local question
  local domain="/Library/Preferences/com.apple.loginwindow"
  local key="LoginwindowText"
  
  # Check for existing login text
  preexisting_text=$(defaults read "${domain}" "${key}" 2>/dev/null || true)
  
  if [[ -n "$preexisting_text" ]]; then
    report "Preexisting login-window text: \"$preexisting_text\""
    question="Enter (a) new login-window text, (b) 'keep' to retain existing text, or (c) 'none' for no login-window text:"
  else
    report "No existing login-window text."
    question="Enter (a) login-window text or (b) 'none' or 'keep' for no message:"
  fi

  user_input=$(get_confirmed_answer_to_question "${question}")
  
  case "${user_input:l}" in  # :l lowercases in Zsh
    keep)
      report "No changes made to login-window text."
      ;;
    none)
      report_action_taken "Login-window message deleted"
      sudo defaults delete "${domain}" "${key}" 2>/dev/null; success_or_not
      ;;
    *)
      report_action_taken "New login-window message: ${user_input}"
      sudo defaults write "${domain}" "${key}" -string "$user_input"; success_or_not
      ;;
  esac
  
  report_end_phase_standard
}
