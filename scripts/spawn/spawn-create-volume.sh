#!/usr/bin/env zsh

function ensure_encrypted_apfs_volume_exists() {
  # Ensure an encrypted APFS volume exists.
  #
  # CONTAINER SPECIFICATION:
  #   Specify exactly one of:
  #     --container <apfs container reference>
  #     --startup-container
  #
  # REQUIRED:
  #   --volume-name <volume name>
  #
  # PASSPHRASE SPECIFICATION:
  #   Choose exactly one of 1PASSWORD, CLEARTEXT, INTERACTIVE immediately below:
  #
  #   1PASSWORD: (specify both of the following)
  #   --op-vault                 <string> 1Password vault name
  #   --op-item-passphrase       <string> item name containing desired volume passphrase
  #
  #   CLEARTEXT (insecure; testing only):
  #   --cleartext-passphrase     <string> passphrase
  #
  #   INTERACTIVE:
  #   --interactive-passphrase   Prompt interactively for the passphrase
  #
  # Examples:
  #
  #   ensure_encrypted_apfs_volume_exists \
  #     --startup-container \
  #     --volume-name "Volume_for_Work_Users" \
  #     --op-vault "$ONEPASSWORD_VAULT_FOR_GENOMAC_USER_CREATION" \
  #     --op-item-passphrase "WORK_PASSWORD"
  #
  #   ensure_encrypted_apfs_volume_exists \
  #     --container "/dev/disk3" \
  #     --volume-name "Test_Volume" \
  #     --cleartext-passphrase "test_password"
  #
  #   ensure_encrypted_apfs_volume_exists \
  #     --startup-container \
  #     --volume-name "Utility_Volume" \
  #     --interactive-passphrase

  report_start_phase_standard
  
  local apfs_container=""
  local use_startup_container=false
  local vol_name=""

  local op_vault=""
  local op_item_passphrase=""
  local cleartext_passphrase=""
  local use_interactive_passphrase=false

  local passphrase=""
  local using_1password=false
  local using_cleartext=false

  while (( $# > 0 )); do
    case "$1" in
      --container)
        apfs_container=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;

      --startup-container)
        use_startup_container=true
        shift
        ;;

      --volume-name)
        vol_name=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;

      --op-vault)
        op_vault=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;

      --op-item-passphrase)
        op_item_passphrase=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;

      --cleartext-passphrase)
        cleartext_passphrase=$(required_value_for_option "$1" "${2-}") || return 1
        shift 2
        ;;

      --interactive-passphrase)
        use_interactive_passphrase=true
        shift
        ;;

      *)
        report_fail "Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  if [[ -n "$apfs_container" && "$use_startup_container" == true ]]; then
    report_fail "Specify either --container or --startup-container, not both."
    return 1
  fi

  if [[ -z "$apfs_container" && "$use_startup_container" == false ]]; then
    report_fail "You must specify either --container or --startup-container."
    return 1
  fi

  if [[ -z "$vol_name" ]]; then
    report_fail "Missing mandatory parameter --volume-name."
    return 1
  fi

  if [[ -n "$op_vault" || -n "$op_item_passphrase" ]]; then
    using_1password=true
  fi

  if [[ -n "$cleartext_passphrase" ]]; then
    using_cleartext=true
  fi

  local passphrase_mode_count=0
  [[ "$using_1password" == true ]] && (( passphrase_mode_count += 1 ))
  [[ "$using_cleartext" == true ]] && (( passphrase_mode_count += 1 ))
  [[ "$use_interactive_passphrase" == true ]] && (( passphrase_mode_count += 1 ))

  if (( passphrase_mode_count != 1 )); then
    report_fail "You specified $passphrase_mode_count passphrase modes.${NEWLINE}Specify exactly one of: 1Password passphrase, cleartext passphrase, or interactive passphrase."
    return 1
  fi

  if [[ "$using_1password" == true ]]; then
    if [[ -z "$op_vault" || -z "$op_item_passphrase" ]]; then
      report_fail "When using 1Password, you must supply both --op-vault and --op-item-passphrase."
      return 1
    fi
  fi

  if [[ "$use_startup_container" == true ]]; then
    if ! apfs_container="$(determine_startup_container)"; then
      report_fail "Failed to determine startup container."
      return 1
    fi
  fi

  if [[ "$using_1password" == true ]]; then
    if ! passphrase="$(
      op read "op://${op_vault}/${op_item_passphrase}/notesPlain"
    )"; then
      report_fail "Failed to retrieve volume passphrase from 1Password."
      return 1
    fi
  elif [[ "$using_cleartext" == true ]]; then
    passphrase="$cleartext_passphrase"
  fi

  report_action_taken "Ensuring encrypted APFS volume '$vol_name' exists in container '$apfs_container'"
  if diskutil apfs list "$apfs_container" | grep -Fq "Name: ${vol_name} "; then
    success_or_not
    report "  - '$vol_name' already exists in '$apfs_container'; skipping creation"
    report_end_phase_standard
    return 0
  fi

  if [[ "$use_interactive_passphrase" == true ]]; then
    if ! diskutil apfs addVolume "$apfs_container" APFS "$vol_name" -passprompt; then
      report_fail "Failed to create encrypted APFS volume '$vol_name' in container '$apfs_container'."
      return 1
    fi
  else
    if ! printf '%s' "$passphrase" | diskutil apfs addVolume "$apfs_container" APFS "$vol_name" -stdinpassphrase; then
      report_fail "Failed to create encrypted APFS volume '$vol_name' in container '$apfs_container'."
      return 1
    fi
  fi

  success_or_not
  report "Created encrypted APFS volume '$vol_name' in container '$apfs_container'"
  report_end_phase_standard
}
