#!/usr/bin/env zsh
set -euo pipefail

# Resolve this test script's dir and source the main script one level up
this_test_path="${0:A}"
this_test_dir="${this_test_path:h}"
source "${this_test_dir}/../provision_vols_and_users.sh"  # does NOT run main()

NAME_OF_NEW_VOLUME="VolumeX"
PATH_OF_APFS_VOLUME="/dev/disk99"

# Choose (by uncommenting exactly one line) whether to test (a) via DRY RUN or (b) for realz
# DRY_RUN=0 # No dry run. Make system changes
DRY_RUN=1 # Force dry run (no system changes)

# Call the function with test data
create_encrypted_apfs_volume "$PATH_OF_APFS_VOLUME" "$NAME_OF_NEW_VOLUME" "dummy-passphrase"
