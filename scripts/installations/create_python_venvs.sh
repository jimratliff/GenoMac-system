#!/usr/bin/env zsh

function conditionally_create_virtual_environment_for_setting_ChatGPT_preferences() {
  # Conditoinally create Python virtual environment for setting ChatGPT preferences.
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_PYTHON_DEPENDENCIES_HAVE_BEEN_INSTALLED" \
    create_virtual_environment_for_setting_ChatGPT_preferences \
    "Skipping creating Python venv for ChatGPT, because this was done in the past."

  report_end_phase_standard
}

function create_virtual_environment_for_setting_ChatGPT_preferences() {
  # Create Python virtual environment for setting ChatGPT preferences.
  report_start_phase_standard

  sudo mkdir -p "$GLOBAL_PYTHON_VENVS"
  sudo chown "$USER" "$GLOBAL_PYTHON_VENVS"
  sudo chmod 0755 "$GLOBAL_PYTHON_VENVS"

	local venv="$GLOBAL_PYTHON_VENV_CHATGPT"
	if [[ ! -x "$venv/bin/python" ]]; then
	  (umask 022; python3 -m venv "$venv")
	fi

	# Install tomlkit
	(umask 022; "$PYTHON_IN_CHATGPT_VENV" -m pip install tomlkit)

  report_end_phase_standard

}
