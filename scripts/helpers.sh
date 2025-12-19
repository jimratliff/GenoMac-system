# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_bootstrap_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_bootstrap_helpers_sh=1
export __already_loaded_genomac_bootstrap_helpers_sh

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
  # Launches (in background if possible) and then quits an app identified by its bundle ID
  # Required in some cases, e.g., iTerm2, where a sufficiently populated plist isn’t available to modify
  #   until the app has been launched once. (I.e., it is not enough simply to have created an empty
  #   plist file, as can be done with the function ensure_plist_exists().
  # Examples:
  #   launch_and_quit_app "com.apple.DiskUtility"
  #   launch_and_quit_app "com.googlecode.iterm2"
  
  local bundle_id="$1"
  report_action_taken "Launch and quit app $bundle_id"
  report_action_taken "Launching app $bundle_id (in the background, if possible)"
  open -gj -b "$bundle_id" 2>/dev/null || open -g -b "$bundle_id" ; success_or_not
  sleep 2
  report_action_taken "Quitting app $bundle_id"
  osascript -e "tell application id \"$bundle_id\" to quit" ; success_or_not
}

function quit_app_by_bundle_id_if_running() {
  # Quit the app identified by its bundle ID if (and only if) it is running.
  # - bundle_id: e.g., "com.tylerhall.Alan"
  #
  # Behavior:
  # - If the app is not running: no output, returns 0.
  # - If the app is running:
  #     1. Request a graceful quit via AppleScript.
  #     2. Sleep briefly to allow a clean shutdown.
  #     3. If still running, force-kill any processes under the app's
  #        Contents/MacOS directory, using Spotlight (mdfind) to locate the .app.
  #
  # Requires:
  # - macOS
  # - mdfind (Spotlight enabled)
  # - report_action_taken, success_or_not helpers already defined.
  
  local delay_in_seconds_for_normal_quitting=3
  local bundle_id="$1"

  # Tests whether the app is currently running
  # If osascript errors (e.g., unknown bundle ID), grep sees nothing and this
  # condition is just false -> we treat that as "not running".
  if ! osascript -e "application id \"$bundle_id\" is running" 2>/dev/null | grep -qi true; then
    # Not running; nothing to do.
    return 0
  fi

  # Request graceful quit
  report_action_taken "App with bundle ID ${bundle_id} is running. Requesting that it quit"
  osascript -e "tell application id \"$bundle_id\" to quit" >/dev/null 2>&1 ; success_or_not

  # Allow some time for the app to shut down and flush any state (plists, etc.).
  sleep $delay_in_seconds_for_normal_quitting

  # If still running, force quit
  if osascript -e "application id \"$bundle_id\" is running" 2>/dev/null | grep -qi true; then
    # Derive the .app path from the bundle ID using Spotlight.
    # We take the first match; if there are multiple installs, that's already
    # a slightly weird situation for an updater.
    local app_path
    app_path=$(mdfind "kMDItemCFBundleIdentifier == '${bundle_id}'" | head -n 1)

    if [[ -n "$app_path" ]]; then
      report_action_taken "App ${bundle_id} still running despite our polite request; forcing quit for processes under ${app_path}/Contents/MacOS/"
      # pkill returns 1 if nothing matched; that's fine for our semantics
      # ("ensure it's not running"), so we mask that with `|| true` to avoid making success_or_not print a ❌.
      pkill -9 -f "${app_path}/Contents/MacOS/" >/dev/null 2>&1 || true
      success_or_not
    else
      # We think it's running but can't find the bundle on disk; that's
      # suspicious enough to mark as a failure in your alert summary.
      report_fail "App ${bundle_id} appears to be running, but its .app could not be found via mdfind; unable to force quit"
      false
    fi
  fi

  return 0
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
  local message="$1"
  printf "%b%s%s%b\n" "$COLOR_ERROR" "$SYMBOL_FAILURE" "$message" "$COLOR_RESET"
  
  # Also append a plain-text version to the alert log, if it's set.
  if [[ -n "${GENOMAC_ALERT_LOG-}" ]]; then
    printf 'FAIL: %s\n' "$message" >>"$GENOMAC_ALERT_LOG"
  fi
}

function report_success() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_SUCCESS.
  printf "%b%s%s%b\n" "$COLOR_SUCCESS" "$SYMBOL_SUCCESS" "$1" "$COLOR_RESET"
}

function report_warning() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_WARNING.
  local message="$1"
  printf "%b%s%s%b\n" "$COLOR_WARNING" "$SYMBOL_WARNING" "$message" "$COLOR_RESET"

  # Also append a plain-text version to the alert log, if it's set.
  if [[ -n "${GENOMAC_ALERT_LOG-}" ]]; then
    printf 'WARN: %s\n' "$message" >>"$GENOMAC_ALERT_LOG"
  fi
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

dump_accumulated_warnings_failures() {
  # Prints all assumulated warnings and/or failures from GENOMAC_ALERT_LOG
  
  # If we somehow never initialized, bail quietly.
  [[ -z "${GENOMAC_ALERT_LOG-}" ]] && return 0
  [[ ! -e "$GENOMAC_ALERT_LOG" ]] && return 0

  if [[ ! -s "$GENOMAC_ALERT_LOG" ]]; then
    echo "✅ No GenoMac warnings or failures detected in this run." >&2
  else
    echo >&2
    echo "═════════ GenoMac warnings / failures (summary) ═════════" >&2
    cat "$GENOMAC_ALERT_LOG" >&2
    echo "════════════════════════ end summary ════════════════════" >&2
    echo "↑ Scroll back in the log to see these in context." >&2
  fi

  rm -f -- "$GENOMAC_ALERT_LOG"
}

is_semantic_version_arg1_at_least_arg2() {
  # is_semantic_version_arg1_at_least_arg2 ARG1 ARG2
  #
  # Returns 0 (success) iff (normalized ARG1) >= (normalized ARG2)
  # according to semantic version ordering.
  #
  # Normalization rules:
  #   - Strips a leading "v" if present
  #   - Removes everything from the first "-" or "+" onward
  #     e.g., "1.3-", "1.3-1", and "1.3+5" would each reduce to "1.3"
  #
  # Examples:
  #   is_semantic_version_arg1_at_least_arg2 "1"   "1.5"  → returns 1 (false)
  #   is_semantic_version_arg1_at_least_arg2 "1.5" "1.0"  → returns 0 (true)
  #   is_semantic_version_arg1_at_least_arg2 "2.2" "2.2"  → returns 0 (true)

  local arg1="$1"
  local arg2="$2"

  arg1="${arg1#v}"
  arg2="${arg2#v}"

  arg1="${arg1%%[-+]*}"
  arg2="${arg2%%[-+]*}"

  is-at-least "$arg2" "$arg1"
}

function copy_resource_between_local_directories() {
  # Helper function to copy a resource between two local directories.
  # The source resource may be either a file or a directory (e.g.,package).
  # Usage: copy_resource_between_local_directories <source_path> <destination_path> [--systemwide]
  #
  # Arguments:
  #   source_path         Full path to the resource in a local directory
  #   destination_path    Full path where the resource should be copied
  #
  # Options:
  #   --systemwide        Deploy systemwide (use sudo, set owner to root:wheel)
  #                       Default: false (deploy for current user)
  #
  # Returns: 0 on success, 1 on failure
  
  local source_path=""
  local destination_path=""
  local systemwide=false

  report_start_phase_standard
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --systemwide)
        systemwide=true
        shift
        ;;
      *)
        if [[ -z "$source_path" ]]; then
          source_path="$1"
        elif [[ -z "$destination_path" ]]; then
          destination_path="$1"
        else
          report_fail "Too many arguments provided to copy_resource_between_local_directories"
          report_end_phase_standard
          return 1
        fi
        shift
        ;;
    esac
  done
  
  # Validate required arguments
  if [[ -z "$source_path" ]] || [[ -z "$destination_path" ]]; then
    report_fail "Usage: copy_resource_between_local_directories <source_path> <destination_path> [--systemwide]"
    return 1
  fi
  
  # Verify source exists
  report_action_taken "Verify that source resource exists"
  if [[ ! -e "$source_path" ]]; then
    report_fail "Source resource not found at: $source_path"
    return 1
  fi
  
  # Determine if source is a file or directory and set appropriate flags/permissions
  local is_directory
  local mode
  local cp_flags
  local chown_flags
  if [[ -d "$source_path" ]]; then
    is_directory=true
    mode="755"  # Directories need execute permission for traversal
    cp_flags="-R"  # Recursive copy for directories
    chown_flags="-R"  # Recursive ownership for directories
    report "Source is a directory/package."
  else
    is_directory=false
    mode="644"  # Files: owner read/write, others read-only
    cp_flags="-f"  # Force copy for files
    chown_flags=""
    report "Source is a regular file, not a directory/package."
  fi
  
  # Set sudo prefix and owner based on deployment type
  local sudo_prefix
  local owner
  if [[ "$systemwide" == true ]]; then
    sudo_prefix="sudo"
    owner="root:wheel"
  else
    sudo_prefix=""
    owner="${USER}:$(id -gn)"
  fi
  
  # Create parent directory
  local parent_dir
  parent_dir=$(dirname "$destination_path")
  report_action_taken "Ensure destination folder exists: $parent_dir"
  $sudo_prefix mkdir -p "$parent_dir" ; success_or_not
  
  # Determine whether we need to copy
  local resource_name
  resource_name=$(basename "$destination_path")
  report_action_taken "Copy ${resource_name} to $(dirname "$destination_path") (idempotent)"
  
  local needs_copy=false
  if [[ ! -e "$destination_path" ]]; then
    needs_copy=true
    report_info "Resource doesn’t exist at destination, will copy"
  elif [[ "$is_directory" == true ]]; then
    # For directories, use rsync dry-run to check if content differs
    if ! rsync -aqn "$source_path/" "$destination_path/" >/dev/null 2>&1; then
      needs_copy=true
      report_info "Directory contents differ, will update"
    fi
  else
    # For files, use cmp
    if ! cmp -s "$source_path" "$destination_path" 2>/dev/null; then
      needs_copy=true
      report_info "File contents differ, will update"
    fi
  fi
  
  if [[ "$needs_copy" == true ]]; then
    # Remove existing destination if it exists and we're updating
    if [[ -e "$destination_path" ]]; then
      report_action_taken "Remove existing resource before copying"
      $sudo_prefix rm -rf "$destination_path" ; success_or_not
    fi
    
    # Copy the resource
    $sudo_prefix cp $cp_flags "$source_path" "$destination_path" ; success_or_not
    report_success "Installed or updated ${resource_name}"
  else
    report_success "${resource_name} already up to date"
  fi
  
  # Set ownership
  report_action_taken "Set ownership to ${owner} on ${destination_path}"
  $sudo_prefix chown $chown_flags "${owner}" "$destination_path" ; success_or_not
  
  # Set permissions (644 for files, 755 for directories)
  report_action_taken "Set permissions to ${mode} on ${destination_path}"
  $sudo_prefix chmod "$mode" "$destination_path" ; success_or_not
  
  # For directories, ensure all subdirectories have proper execute permissions
  if [[ "$is_directory" == true ]]; then
    $sudo_prefix find "$destination_path" -type d -exec chmod 755 {} \; 2>/dev/null
  fi

  report_end_phase_standard
  
  return 0
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
