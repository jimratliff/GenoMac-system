#!/usr/bin/env zsh

function conditionally_clone_genomac_user_using_HTTPS() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_GENOMAC_USER_HAS_BEEN_CLONED" \
    clone_genomac_user_repo_using_HTTPS \
    "Skipping cloning GenoMac-user, because this was done in the past."

  report_end_phase_standard
}

function clone_genomac_user_repo_using_HTTPS() {
  # Clone GenoMac-user repo to GENOMAC_USER_LOCAL_DIRECTORY using HTTPS
  #
  # If GenoMac-user is already cloned to GENOMAC_USER_LOCAL_DIRECTORY, sets the
  # $PERM_GENOMAC_USER_HAS_BEEN_CLONED state and returns normally.
  
  report_start_phase_standard

  report_action_taken "Cloning GenoMac-user to your home directory using HTTPS."

  local local_cloning_dir="$GENOMAC_USER_LOCAL_DIRECTORY"
  local repo_url="${GENOMAC_USER_HTTP_REPO_URL}"

  report_action_taken "Checking for existing repo cloned here"
  local existing_remote
  local existing_repo_name
  if [[ -d "$local_cloning_dir/.git" ]]; then
    existing_remote=$(git -C "$local_cloning_dir" remote get-url origin 2>/dev/null)
    existing_repo_name=$(basename "$existing_remote" .git)
    if [[ "$existing_repo_name" == "$GENOMAC_USER_REPO_NAME" ]]; then
      report "Repository $GENOMAC_USER_REPO_NAME already cloned at: $local_cloning_dir" ; success_or_not
      set_genomac_system_state "$PERM_GENOMAC_USER_HAS_BEEN_CLONED"
      return 0
    fi
    report_fail "Directory contains a different repository: $existing_repo_name (expected: $GENOMAC_USER_REPO_NAME)"
    report_end_phase_standard
    return 1
  fi

  if [[ -n "$(ls -A "$local_cloning_dir" 2>/dev/null)" ]]; then
    report_fail "Directory exists but is not empty (and is not a git repository): $local_cloning_dir"
    report_end_phase_standard
    return 1
  fi
  
  report_action_taken "Cloning repo: $repo_url into $local_cloning_dir"
  git clone "$repo_url" "$local_cloning_dir" ; success_or_not

  report_end_phase_standard
}
