# For syntax/behavior of just, see https://github.com/casey/just

# use `just --choose` to be presented with an interactive chooser to select the particular recipe

# Typing only 'just' will run this default recipe, displaying interactive chooser.
default:
	@just --choose

system-states command:
    zsh scripts/utilities/system_state_utilities.zsh {{command}}

show-system-states:
    just system-states show

clear-system-sesh-states:
    just system-states clear-seshion

clear-all-system-states:
    just system-states clear-all
