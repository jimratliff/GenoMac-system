#!/usr/bin/env zsh
set -euo pipefail

# Resolve this test script's dir and source the main script one level up
this_test_path="${0:A}"
this_test_dir="${this_test_path:h}"
source "${this_test_dir}/../provision_vols_and_users.sh"  # does NOT run main()

# Choose (by uncommenting exactly one line) whether to test (a) via DRY RUN or (b) for realz
# DRY_RUN=0 # No dry run. Make system changes
DRY_RUN=1 # Force dry run (no system changes)

SHORT_NAME_FOR_NEW_USER="testuser"
VOLUME_ON_WHICH_TO_CREATE_NEW_USER_DIRECTORY="VolumeX"
USER_ID_FOR_NEW_USER=555
FAUX_VOCATION="tester"

# Choose by uncommenting exactly one line) the image file for the user’s login picture
LOGIN_PICTURE=""
#LOGIN_PICTURE="test_user.pic

# Minimal fake mappings (normally filled by main() parsing JSON)
# "dummy-passphrase" won’t (I hope!) be the actual encryption password of the volume; rather,
# it will be inherited as the password for the new user.
typeset -A VOL_PASS VOC_VOL
VOL_PASS["$VOLUME_ON_WHICH_TO_CREATE_NEW_USER_DIRECTORY"]="dummy-passphrase"
VOC_VOL["$FAUX_VOCATION"]="$VOLUME_ON_WHICH_TO_CREATE_NEW_USER_DIRECTORY"

# Call the function with canned test data
create_local_user_account "$SHORT_NAME_FOR_NEW_USER" "$USER_ID_FOR_NEW_USER" "$FAUX_VOCATION" "$LOGIN_PICTURE"
