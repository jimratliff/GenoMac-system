#!/usr/bin/env zsh

function get_loginwindow_message() {
  # Get login-window message
  # Displays any preexisting login-window message
  # Asks user whether they want to supply new text. - I.e., if not, existing text 
  # is retained or, if none existing, there will be no loginwindow message.
  # If user wants to supply a message, the user is queried for the text and 
  # iterates until user confirms satisfaction.
  
  report_start_phase_standard
  report_action_taken "Set login-window message"
  
  # Check for existing login text
  preexisting_text=$(defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null || true)
  
  if [[ -n "$preexisting_text" ]]; then
    report "Preexisting login-window text: \"$preexisting_text\""
  else
    report "No existing login-window text."
  fi
  
  # Ask whether to change login-window text
  if get_yes_no_answer_to_question "Would you like to change login-window text?"; then
    # Confirmation loop allowing blank input
    while true; do
      ask_question "Enter desired login-window message (leave blank for none):"
      read "user_input?→ "
      
      if get_yes_no_answer_to_question "You entered: \"$user_input\". Is this correct?"; then
        break
      fi
    done
  
    report "Final choice: \"$user_input\""
    if [[ -n "$user_input" ]]; then
    	report_action_taken "New login-window message: ${user_input}"
      sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText -string "$user_input"; success_or_not
    else
    	report_action_taken "Login-window message deleted"
      sudo defaults delete /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null; success_or_not
    fi
  else
    report "No changes made to login-window text."
  fi
  
  report_end_phase_standard
}
