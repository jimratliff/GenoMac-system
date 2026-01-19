#!/usr/bin/env zs

function interactive_sign_into_MAS() {
  report_start_phase_standard
  
  launch_app_and_prompt_user_to_act \
    --show-doc "${GENOMAC_USER_DOCS_TO_DISPLAY_DIRECTORY}/TextExpander_how_to_configure.md" \
    "$BUNDLE_ID_APP_STORE" \
    "Follow the instructions in the Quick Look window to log into the App Store"
    
  report_end_phase_standard
}
