# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_bootstrap_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_bootstrap_helpers_sh=1

############### HELPERS

# Set up and assign colors
ESC_SEQ="\033["

COLOR_RESET="${ESC_SEQ}0m"

COLOR_BLACK="${ESC_SEQ}30;01m"
COLOR_RED="${ESC_SEQ}31;01m"
COLOR_GREEN="${ESC_SEQ}32;01m"
COLOR_YELLOW="${ESC_SEQ}33;01m"
COLOR_BLUE="${ESC_SEQ}34;01m"
COLOR_MAGENTA="${ESC_SEQ}35;01m"
COLOR_CYAN="${ESC_SEQ}36;01m"
COLOR_WHITE="${ESC_SEQ}37;01m"

COLOR_QUESTION="$COLOR_MAGENTA"
COLOR_REPORT="$COLOR_BLUE"
COLOR_ADJUST_SETTING="$COLOR_CYAN"
COLOR_ACTION_TAKEN="$COLOR_GREEN"
COLOR_WARNING="$COLOR_YELLOW"
COLOR_ERROR="$COLOR_RED"
COLOR_SUCCESS="$COLOR_GREEN"
COLOR_KILLED="$COLOR_RED"

SYMBOL_SUCCESS="✅ "
SYMBOL_FAILURE="❌ "
SYMBOL_QUESTION="❓ "
SYMBOL_ADJUST_SETTING="⚙️  "
SYMBOL_KILLED="☠️ "
SYMBOL_ACTION_TAKEN="🪚 "
SYMBOL_WARNING="🚨 "

# Example usage
# Each %b and %s maps to a successive argument to printf
# printf "%b[ok]%b %s\n" "$COLOR_GREEN" "$COLOR_RESET" "some message"

function keep_sudo_alive() {
  report_action_taken "I very likely am about to ask you for your administrator password. Do you trust me??? 😉"

  # Update user’s cached credentials for `sudo`.
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until this shell exits
  while true; do 
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &  # background process, silence errors
}

safe_source() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  # Usage:
  #  safe_source "${PREFS_FUNCTIONS_DIR}/set_safari_settings.sh"
  local file="$1"
  if ! source "$file"; then
    echo "ERROR: Failed to source $file"
    exit 1
  fi
}

function launch_and_quit_app() {
  # Launches and then quits an app identified by its bundle ID
  # Required in some cases, e.g., iTerm2, where a sufficiently populated plist isn’t available to modify
  #   until the app has been launched once. (I.e., it is not enough simply to have created an empty
  #   plist file, as can be done with the function ensure_plist_exists().
  # Examples:
  #   launch_and_quit_app "com.apple.DiskUtility"
  #   launch_and_quit_app "com.googlecode.iterm2"
  
  local bundle_id="$1"
  report_action_taken "Launch and quit app $bundle_id in order that it will have preferences to modify"
  report_action_taken "Launching app $bundle_id"
  open -b "$bundle_id" ; success_or_not
  sleep 2
  report_action_taken "Quitting app $bundle_id"
  osascript -e "tell application id \"$bundle_id\" to quit" ; success_or_not
}

function success_or_not() {
  # Print SYMBOL_SUCCESS if success (based on error code); otherwise SYMBOL_FAILURE
  if [[ $? -eq 0 ]]; then
    printf " ${SYMBOL_SUCCESS}\n"
  else
    printf "\n${SYMBOL_FAILURE}\n"
  fi
}

function legacy_plist_path_from_domain() {
  # Constructs path of the .plist file corresponding to the defaults domain passed as an argument.
  # Usage:
  #   local plist_path=$(legacy_plist_path_from_domain "$domain")
  local domain="$1"
  local plist_path="$HOME/Library/Preferences/${domain}.plist"
  echo "$plist_path"
}

function sandboxed_plist_path_from_domain() {
  # Constructs path of the .plist file for a sandboxed app corresponding to the defaults domain 
  # passed as an argument.
  # Usage:
  #   local plist_path=$(sandboxed_plist_path_from_domain "$domain")
  local domain="$1"
  # local plist_path="$HOME/Library/Preferences/${domain}.plist"
  local plist_path="$HOME/Library/Containers/${domain}/Data/Library/Preferences/${domain}.plist"
  echo "$plist_path"
}

function ensure_plist_path_exists() {
  # Used to ensures the plist file at the supplied path exists.
  # Note: In some cases, e.g., iTerm2, a merely nonempty plist is insufficient to support all desired
  #       modifications. In that case, the function launch_and_quit_app() is used to initialize the plist.
  # Usage:
  #   domain="com.apple.DiskUtility"
  #   plist_path=$(legacy_plist_path_from_domain $domain")
  #   ensure_plist_path_exists "${plist_path}"
  #
  #   domain="com.apple.Preview""
  #   plist_path=$(sandboxed_plist_path_from_domain $domain")
  #   ensure_plist_path_exists "${plist_path}"
  
  local plist_path="$1"
  report_action_taken "Ensure that plist exists at: ${plist_path}"
  if [[ ! -f "$plist_path" ]]; then
    report_action_taken "plist doesn’t exist; creating…"

    # Ensure the directory structure exists
    local plist_dir=$(dirname "$plist_path")
    if [[ ! -d "$plist_dir" ]]; then
      report_action_taken "Creating directory structure: ${plist_dir}"
      mkdir -p "$plist_dir"
    fi
    
    local fictitious_key="_fictitious_key"
    plutil -create xml1 "$plist_path" && \
    plutil -insert "${fictitious_key}" -string "Nothing to see here; move along…" "$plist_path" && \
    plutil -remove "${fictitious_key}" "$plist_path"
    if [[ ! -f "$plist_path" ]]; then
      report_fail "${plist_path} still doesn’t exist; FAIL"
      return 1
    else
      report_success "${plist_path} now exists."
    fi
  else
    report_success "${plist_path} already exists."
  fi
}

function ask_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION
  printf "%b%s%s%b\n" "$COLOR_QUESTION" "$SYMBOL_QUESTION" "$1" "$COLOR_RESET"
}

function get_nonblank_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, iterating until user provides a nonblank response.
  #
  # Usage example: name=$(get_nonblank_answer_to_question "What should the diff be named?")
  local prompt="$1"
  local answer

  while true; do
    ask_question "$prompt" >&2 # Redirects question to stderr to keep it out of returned string
    read "answer?→ "
    [[ -n "${answer// }" ]] && break
  done

  echo "$answer"
}

function sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-'
}

function get_confirmed_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, ask user to confirm, and iterate until user provides an affirmative confirmation.
  #
  # Usage example: folder=$(get_confirmed_answer_to_question "Where should I save the results?")
  local prompt="$1"
  local answer confirm

  while true; do
    ask_question "$prompt"
    read "answer?→ "
    [[ -z "${answer// }" ]] && continue

    ask_question "You entered: '$answer'. Is this correct? (y/n)"
    read "confirm?→ "
    case "$confirm" in
      [Yy]*) break ;;
    esac
  done

  echo "$answer"
}

function get_yes_no_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, iterating until user provides either a yes or no equivalent.
  #
  # Usage example: 
  #     if get_yes_no_answer_to_question "Do you want to continue?"; then
  #       echo "✅ Proceeding"
  #     else
  #       echo "❌ Aborted"
  #     fi
  
  local prompt="$1"
  local response

  while true; do
    ask_question "$prompt (y/n)"
    read "response?→ "
    case "${response:l}" in  # `:l` lowercases in Zsh
      y|yes) echo "yes"; return 0 ;;
      n|no)  echo "no";  return 1 ;;
    esac
  done
}

function force_user_logout(){
  report_action_taken $'\n\nYou are about to be logged out…'
  sleep 3  # Give user time to read the message

  # Graceful logout using familiar system behavior
  osascript -e 'tell application "System Events" to log out'
}

function report() {
  # Output supplied line of text in a distinctive color.
  printf "%b%s%b\n" "$COLOR_REPORT" "$1" "$COLOR_RESET"
}

function report_fail() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_FAILURE.
  printf "%b%s%s%b\n" "$COLOR_ERROR" "$SYMBOL_FAILURE" "$1" "$COLOR_RESET"
}

function report_success() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_SUCCESS.
  printf "%b%s%s%b\n" "$COLOR_SUCCESS" "$SYMBOL_SUCCESS" "$1" "$COLOR_RESET"
}

function report_warning() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_WARNING.
  printf "%b%s%s%b\n" "$COLOR_WARNING" "$SYMBOL_WARNING" "$1" "$COLOR_RESET"
}

function report_adjust_setting() {
  # Output supplied line of text in a distinctive color, prefaced by "$SYMBOL_ADJUST_SETTING.
  # It is intentional to NOT have a newline. This will be supplied by success().
  printf "%b%s%s%b" "$COLOR_ADJUST_SETTING" "$SYMBOL_ADJUST_SETTING" "$1" "$COLOR_RESET"
}

function report_about_to_kill_app() {
  # Takes `app` as argument
  # Outputs message that the app was killed.
  printf "%b%s %s is being killed (if necessary) %b" "$COLOR_KILLED" "$SYMBOL_KILLED" "$1" "$COLOR_RESET"
}

function report_action_taken() {
  # Output supplied line of text in a distinctive color, prefaced by "$SYMBOL_ADJUST_SETTING.
  printf "%b%s%s%b\n" "$COLOR_ACTION_TAKEN" "$SYMBOL_ACTION_TAKEN" "$1" "$COLOR_RESET"
}

# Hard-deprecated shim: do NOT call this anymore.
# Intentional failure that tells callers how to migrate.
function ensure_plist_exists() {
  emulate -L zsh
  set -u  # don't pipefail/e, we want to reliably emit the message

  report_fail "‘ensure_plist_exists()’ is deprecated. Use ensure_plist_path_exists() instead"
  return 64  # EX_USAGE-style to force refactor
}

################################################################################
# PHASE REPORTING HELPERS
#
# The below four functions provide a consistent way to mark in the terminal output 
# the start and end of output-intensive or semantically distinct “phases” within the
# bootstrap process.
#
# They emit color-coded separator blocks, with textual content like:
#
#   ********************************************************************************
#   Entering: configure_firewall
#   ********************************************************************************
#
# USAGE GUIDELINES:
#
# ⏺ report_start_phase
# ⏺ report_end_phase
#
#   Use these when you want fine-grained control.
#
#   • Zero arguments → print "Entering phase" or "Leaving phase", respectively
#   • One argument   → print the argument exactly as a message line (e.g. emoji + text)
#   • Two arguments  → interpret as function name and file name; format as:
#       Entering: func_name (file: /path/to/file)
#     If the second argument is "-", the file-name clause is omitted:
#       Entering: func_name
#
# ⏺ report_start_phase_standard
# ⏺ report_end_phase_standard
#
#   Use these inside functions when you want standard behavior without manual quoting
#   or boilerplate. These extract (a) the function name from the call stack and,
#   (b) if available, the file name using `functions -t`.
#
#   - If the file name is unavailable, the file-name clause is silently omitted.
#   - These accept no arguments — just call them:
#
#       function configure_firewall() {
#         report_start_phase_standard
#         # ...
#         report_end_phase_standard
#       }
#
#   This is the recommended style for all GenoMac bootstrap functions.
#
################################################################################

function report_start_phase() {
  printf "\n%b%s%b\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      printf "%bEntering: %s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET"
    else
      printf "%bEntering: %s (file: %s)%b\n" "$COLOR_MAGENTA" "$1" "$2" "$COLOR_RESET"
    fi
  elif (( $# == 1 )); then
    printf "%b%s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET"
  else
    printf "%bEntering phase%b\n" "$COLOR_MAGENTA" "$COLOR_RESET"
  fi

  printf "%b%s%b\n\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET"
}

function report_end_phase() {
  printf "\n%b%s%b\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      printf "%bLeaving: %s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET"
    else
      printf "%bLeaving: %s (file: %s)%b\n" "$COLOR_YELLOW" "$1" "$2" "$COLOR_RESET"
    fi
  elif (( $# == 1 )); then
    printf "%b%s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET"
  else
    printf "%bLeaving phase%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
  fi

  printf "%b%s%b\n\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET"
}

function report_start_phase_standard() {
  local fn_name="${funcstack[2]}"
  local fn_file="$(functions -t "$fn_name" 2>/dev/null)"
  [[ -n "$fn_file" && "$fn_file" == "$HOME"* ]] && fn_file="~${fn_file#$HOME}"

  [[ -z "$fn_file" ]] && fn_file="-"  # Sentinel: no file

  report_start_phase "$fn_name" "$fn_file"
}

function report_end_phase_standard() {
  local fn_name="${funcstack[2]}"
  local fn_file="$(functions -t "$fn_name" 2>/dev/null)"
  [[ -n "$fn_file" && "$fn_file" == "$HOME"* ]] && fn_file="~${fn_file#$HOME}"

  [[ -z "$fn_file" ]] && fn_file="-"  # Sentinel: no file

  report_end_phase "$fn_name" "$fn_file"
}
