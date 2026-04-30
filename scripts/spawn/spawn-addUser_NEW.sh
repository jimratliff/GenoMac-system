#!/usr/bin/env zshsdfsdfsdf

function sysadminctl_adduser() {
	# An interface to the addUser subcommand of sysadminctl.
	#
	# Creates a new user via sysadminctl -addUser, including enabling Secure Token.
	# 
	# Intended usage is to provide the password for each of (a) the new user and (b) an
	# existing admin user with a Secure Token by providing the name of a 1Password vault and
	# the name of the items in that vault that contain those two passwords. (This reduces
	# the security exposure relative to passing cleartext passwords between functions.)
	# (Alternatively, but insecurely, cleartext passwords can be supplied, primarily for
	# testing purposes.)
	#
	# This function requires credentials for an existing admin user with a Secure Token.
	# After creation, it confirms that Secure Token is enabled for the new user.
	# If Secure Token is not confirmed enabled, the function fails.
	#
	# Parameters:
	#   --short-name                mandatory  <string> short user name
	#   --full-name                            <string> full user name
	#   --uid                       mandatory  <integer> UID
	#   --home                      mandatory  <string> full path to home directory
	#   --avatar-path                          <string> full path to avatar file
	#   --admin-user-name           mandatory  <string> short name of existing admin user
	#
	#   PASSWORD SPECIFICATIONS:
	#   Specify either:
	#     (a) 1Password vault + item names for both new-user and admin-user passwords
	#   or
	#     (b) cleartext passwords for both (testing only)
	#
	#   1PASSWORD:
	#   --op-vault                             <string> 1Password vault name
	#   --op-item-user-password                <string> item name containing password for --short-name
	#   --op-item-admin-password               <string> item name containing password for --admin-user-name
	#
	#   CLEARTEXT (insecure; testing only):
	#   --cleartext-password-user              <string> password for --short-name
	#   --cleartext-password-admin  		   <string> password for --admin-user-name
	#
	#   --hint                                 <string> password hint
	#
	#   --not-an-admin                         If supplied, new user will NOT be an admin.
	#                                          Default: new user WILL be an admin.

	report_start_phase_standard

	local short_name=""
	local full_name=""
	local uid=""
	local home=""
	local avatar_path=""
	local admin_user_name=""

	local op_vault=""
	local op_item_user_password=""
	local op_item_admin_password=""
	local cleartext_password_user=""
	local cleartext_password_admin=""

	local hint=""
	local new_user_is_admin=true

	local user_password=""
	local admin_password=""

	local using_1password=false
	local using_cleartext=false
	local -a cmd

	while (( $# > 0 )); do
		case "$1" in
			--short-name)
				short_name=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--full-name)
				full_name=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--uid)
				uid=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--home)
				home=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--avatar-path)
				avatar_path=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--admin-user-name)
				admin_user_name=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--op-vault)
				op_vault=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--op-item-user-password)
				op_item_user_password=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--op-item-admin-password)
				op_item_admin_password=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--cleartext-password-user)
				cleartext_password_user=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--cleartext-password-admin)
				cleartext_password_admin=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--hint)
				hint=$(required_value_for_option "$1" "${2-}") || return 1
				shift 2
				;;
			--not-an-admin)
				new_user_is_admin=false
				shift
				;;
			*)
				report_fail "Unknown parameter: $1"
				return 1
				;;
		esac
	done

	if [[ -z "$short_name" ]]; then
		report_fail "Missing mandatory parameter --short-name."
		return 1
	fi

	if [[ -z "$uid" ]]; then
		report_fail "Missing mandatory parameter --uid."
		return 1
	fi

	if [[ -z "$home" ]]; then
		report_fail "Missing mandatory parameter --home."
		return 1
	fi

	if [[ -z "$admin_user_name" ]]; then
		report_fail "Missing mandatory parameter --admin-user-name."
		return 1
	fi

	if [[ -n "$op_vault" || -n "$op_item_user_password" || -n "$op_item_admin_password" ]]; then
		using_1password=true
	fi

	if [[ -n "$cleartext_password_user" || -n "$cleartext_password_admin" ]]; then
		using_cleartext=true
	fi

	if [[ "$using_1password" == true && "$using_cleartext" == true ]]; then
		report_fail "Specify passwords either via 1Password parameters or via cleartext parameters, not both."
		return 1
	fi

	if [[ "$using_1password" == false && "$using_cleartext" == false ]]; then
		report_fail "You must specify passwords either via 1Password parameters or via cleartext parameters."
		return 1
	fi

	if [[ "$using_1password" == true ]]; then
		if [[ -z "$op_vault" || -z "$op_item_user_password" || -z "$op_item_admin_password" ]]; then
			report_fail "When using 1Password, you must supply --op-vault, --op-item-user-password, and --op-item-admin-password."
			return 1
		fi
	fi

	if [[ "$using_cleartext" == true ]]; then
		if [[ -z "$cleartext_password_user" || -z "$cleartext_password_admin" ]]; then
			report_fail "When using cleartext passwords, you must supply both --cleartext-password-user and --cleartext-password-admin."
			return 1
		fi
	fi

	if [[ "$using_1password" == true ]]; then
		if ! user_password="$(
			read_1password_item_password "$op_vault" "$op_item_user_password"
		)"; then
			report_fail "Failed to retrieve the new user's password from 1Password."
			return 1
		fi

		if ! admin_password="$(
			read_1password_item_password "$op_vault" "$op_item_admin_password"
		)"; then
			report_fail "Failed to retrieve the admin user's password from 1Password."
			return 1
		fi
	else
		user_password="$cleartext_password_user"
		admin_password="$cleartext_password_admin"
	fi

	cmd=(
		sysadminctl
		-addUser "$short_name"
		-UID "$uid"
		-password "$user_password"
		-home "$home"
		-adminUser "$admin_user_name"
		-adminPassword "$admin_password"
	)

	if [[ -n "$full_name" ]]; then
		cmd+=(-fullName "$full_name")
	fi

	if [[ -n "$hint" ]]; then
		cmd+=(-hint "$hint")
	fi

	if [[ -n "$avatar_path" ]]; then
		cmd+=(-picture "$avatar_path")
	fi

	if [[ "$new_user_is_admin" == true ]]; then
		cmd+=(-admin)
	fi

	report "About to create user ${short_name} with home directory ${home}."

	if [[ "$new_user_is_admin" == true ]]; then
		report "New user will be created as an admin user."
	else
		report "New user will be created as a standard user."
	fi

	# Do not log the full command, because it contains passwords in argv.
	if ! "${cmd[@]}"; then
		report_fail "sysadminctl failed while creating user ${short_name}."
		return 1
	fi

	if ! confirm_secure_token_was_enabled_for_user "$short_name"; then
		report_fail "User ${short_name} was created, but Secure Token was not confirmed enabled."
		return 1
	fi

	report_end_phase_standard
}
