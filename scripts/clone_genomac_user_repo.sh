#!/bin/zsh

function conditionally_clone_genomac_user() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_GENOMAC_USER_HAS_BEEN_CLONED" \
    clone_genomac_user_repo \
    "Skipping cloning GenoMac-user, because this was done in the past."

  report_end_phase_standard
}

function clone_genomac_user_repo() {
  # Clone GenoMac-user repo to GENOMAC_USER_LOCAL_DIRECTORY
  report_start_phase_standard

  local local_cloning_dir="$GENOMAC_USER_LOCAL_DIRECTORY"
  local repo_url="$GENOMAC_USER_REPO_URL"

  report_action_taken "Ensuring target directory exists (but cannot be nonempty): $local_cloning_dir"
  mkdir -p "$local_cloning_dir"; success_or_not
  if [[ -n "$(ls -A "$local_cloning_dir" 2>/dev/null)" ]]; then
    report_error "Directory is not empty: $local_cloning_dir"
    return 1
  fi

  report_action_taken "Changing directory to: $local_cloning_dir"
  cd "$local_cloning_dir"; success_or_not

  report_action_taken "Cloning repo: $repo_url"
  git clone "$repo_url" .; success_or_not

  report_action_taken "The repo has been cloned to ${local_cloning_dir} and you are now in that local directory."

  report_end_phase_standard
}
