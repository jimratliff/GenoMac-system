# This file assumes GENOMAC_HELPER_DIR is already set in the current shell
# to the absolute path of the directory containing helpers.sh.
# That variable must be defined before this file is sourced.

if [[ -z "${GENOMAC_HELPER_DIR:-}" ]]; then
  echo "❌ GENOMAC_HELPER_DIR is not set. Please source `initial_prefs.sh` first."
  return 1
fi

source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################


function get_Mac_names() {
############### Get and optionally set Mac computer names
report_start_phase_standard
report_action_taken "Get and optionally set Mac ComputerName and LocalHostName"

# - Display current ComputerName to user, offering opportunity to change it.
#   - If ComputerName has been “mangled” with a ' (nnn)' suffix (e.g., 'MyComputerName (5)'), strip that
#     ' (nnn)' suffix, and alert user that this has occurred.
#   - Offer the user to chance to change ComputerName.
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

# Get current ComputerName
current_name=$(sudo systemsetup -getcomputername 2>/dev/null | sed 's/^Computer Name: //')
echo "Current ComputerName: \"$current_name\""

# Assume name is clean unless proven otherwise
final_name_is_dirty=false

# If current_name ends with ' (###)', clean it
if echo "$current_name" | grep -qE ' \([0-9]+\)$'; then
  final_name=$(echo "$current_name" | sed -E 's/ \([0-9]+\)$//')
  report_action_taken "ComputerName appears to have been auto-mangled. I have unmangled it: \"$final_name\""
  final_name_is_dirty=true
fi

# Ask whether to change the ComputerName
while true; do
  echo -n "Would you like to change the ComputerName? (y/n): "
  read choice
  if [[ "$choice" =~ ^[YyNn]$ ]]; then
    break
  else
    echo "Invalid response. Please enter \"y\" or \"n\"."
  fi
done

if [[ "$choice" =~ ^[Yy]$ ]]; then
  while true; do
    echo -n "Enter desired ComputerName: "
    read new_name_raw

    # Strip leading/trailing whitespace
    new_name=$(echo "$new_name_raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    echo "You entered: \"$new_name\""
    echo -n "Is this what you want? (y/n): "
    read confirmation

    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
      final_name="$new_name"
      final_name_is_dirty=true
      break
    fi
  done
else
  final_name="$current_name"
  echo "Keeping existing ComputerName."
fi

# Final assignment, if needed
if [[ "$final_name_is_dirty" == true ]]; then
  report_action_taken "Assigning ComputerName to $final_name"
  sudo systemsetup -setcomputername "$final_name" 2> >(grep -v '### Error:-99' >&2); success_or_not
fi

# Derive LocalHostName by sanitizing ComputerName
# - Replace all whitespace with hyphens
# - Remove all but alphanumerics and hyphens
# - Remove leading/trailing hyphens (which also removes any originally leading/trailing whitespace)

sanitized_name=$(echo "$final_name" \
  | tr '[:space:]' '-' \
  | tr -cd '[:alnum:]-' \
  | sed 's/^-*//;s/-*$//')

echo "Sanitized LocalHostName: \"$sanitized_name\""
sudo scutil --set LocalHostName "$sanitized_name"; success_or_not

# Display final names
echo ""
printf "Final name settings:\n"
printf "ComputerName:   %s\n" "$(sudo scutil --get ComputerName 2>/dev/null || echo "(not set)")"
printf "LocalHostName:  %s\n" "$(sudo scutil --get LocalHostName 2>/dev/null || echo "(not set)")"
printf "HostName:       %s\n" "$(sudo scutil --get HostName 2>/dev/null || echo "(not set)")"

report_end_phase_standard

}
