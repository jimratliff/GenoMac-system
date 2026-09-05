#!/usr/bin/env zsh

function conditionally_install_via_homebrew() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_HOMEBREW_APPS_HAVE_BEEN_INSTALLED" \
    install_via_homebrew \
    "Skipping installation of apps via Homebrew, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_via_homebrew() {
  # Installs, upgrades, and removes no-longer-desired Homebrew packages.
  #
  # For nonobvious reasons, brew install requires a password to install some casks
  # Preemptively calling `keep_sudo_alive` doesn’t prevent this
  report_start_phase_standard

  local brewfile_path
  brewfile_path="${GMS_HOMEBREW}/Brewfile"

  # Updates Homebrew itself and its package definitions (formulae and casks) from the remote repository
  report_action_taken "Updating Homebrew itself and package definitions"
  brew update ; success_or_not

  # Remove installed Homebrew items that are not declared in the aggregate Brewfile.
  # This is the replacement for the old `brew bundle install --cleanup`.
  report_action_taken "Removing Homebrew items not declared in Brewfile"
  brew bundle cleanup --file="${brewfile_path}" --force ; success_or_not

  # Installs packages, etc. from Brewfile
  report_action_taken "Install and upgrading Homebrew items declared in Brewfile (and its children)"
  report_warning "Don’t walk away! You’ll be required to enter your administrator password for some apps."
  # brew bundle install --file="${brewfile_path}" ; success_or_not
  brew bundle install --file="${brewfile_path}" --verbose ; success_or_not

  # Reconcile again after install. This catches anything made removable by dependency changes.
  report_action_taken "Removing Homebrew items not declared in Brewfile after install"
  brew bundle cleanup --file="${brewfile_path}" --force ; success_or_not

  # Removes stale lock files, outdated downloads, and old versions/caches
  report_action_taken "Cleans up Homebrew caches and old versions"
  brew cleanup ; success_or_not

  # Sets state to indicate that Homebrew has been used at least once to install apps
  # This ensures basic existence of non-builtin apps on which other parts of GenoMac-system relies
  set_genomac_system_state "$PERM_HOMEBREW_HAS_INSTALLED_APPS_AT_LEAST_ONCE"

  report_end_phase_standard

}

function apply_homebrew_trust() {
  # Applies `brew trust` to each entry in the supplied trust file.
  # Allows for blank lines and # comments
  report_start_phase_standard
  
  local trust_file="${1:?missing trust file}"
  local extra
  local kind
  local name
  
  local -i line_number=0

  if [[ ! -r "$trust_file" ]]; then
    report_fail "Cannot read Homebrew trust file: “${trust_file}”"
    return 1
  fi

  while IFS=$' \t' read -r kind name extra ||
        [[ -n "$kind$name$extra" ]]; do
    line_number=$((line_number + 1))

    # Skip blank lines and full-line comments.
    case "$kind" in
      ''|\#*) continue ;;
    esac

    # Require a name; allow only a comment after it.
    if [[ -z "$name" || "$name" == -* || ( -n "$extra" && "$extra" != \#* ) ]]; then
      report_fail "Expected type and name, optionally followed by # comment${NEWLINE}${trust_file} at line: ${line_number}."
      return 1
    fi

    case "$kind" in
      formula|cask|tap) ;;
      *)
        report_fail "Unknown trust type${NEWLINE}${trust_file} at line: ${line_number} kind: ${kind}."
        return 1
        ;;
    esac

    report_adjust_setting "Trusting Homebrew ${kind}: ${name}"
    brew trust "--${kind}" "$name" || return 1
  done < "$trust_file"

  report_end_phase_standard
  return 0
}

