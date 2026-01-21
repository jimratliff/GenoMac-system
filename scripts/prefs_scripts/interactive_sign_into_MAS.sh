#!/usr/bin/env zs

function conditionally_interactive_sign_into_MAS() {
  report_start_phase_standard
  
  run_if_system_has_not_done \
    "$PERM_MAC_APP_STORE_IS_SIGNED_INTO" \
    interactive_sign_into_MAS \
    "Skipping signing into Mac App Store, because user has done this in the past."
    
  report_end_phase_standard
}

function interactive_sign_into_MAS() {
  report_start_phase_standard
  
  launch_app_and_prompt_user_to_act \
    --show-doc "${GENOMAC_SYSTEM_LOCAL_DOCS_TO_DISPLAY}/MAS_how_to_log_in.md" \
    "$BUNDLE_ID_APP_STORE" \
    "Follow the instructions in the Quick Look window to log into the App Store"
    
  report_end_phase_standard
}
