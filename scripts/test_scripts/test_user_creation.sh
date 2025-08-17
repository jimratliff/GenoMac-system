#!/usr/bin/env zsh
set -euo pipefail

# Resolve this test script's dir and source the main script one level up
this_test_path="${0:A}"
this_test_dir="${this_test_path:h}"
source "${this_test_dir}/../provision_vols_and_users.sh"  # does NOT run main()

# DRY_RUN=0 # No dry run. Make system changes
DRY_RUN=1 # Force dry run (no system changes)

# Minimal fake mappings (normally filled by main() parsing JSON)
typeset -A VOL_PASS VOC_VOL
VOL_PASS["VolumeX"]="dummy-passphrase"
VOC_VOL["tester"]="VolumeX"

# Call the function with canned test data
create_local_user_account "TestUser" "555" "tester" "TestUser.png"
