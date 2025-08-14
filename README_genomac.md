# Project GenoMac: A genetic template for my Macs and their associated user accounts

## TO DO/CONSIDER
Consider moving (a) `make stow-dotfiles` and (b) `clone_genomac_dotfiles_repo.sh` from this repo into the GenoMac-bootstrap repo. This would (a) require `brew install stow` being added there but (b) would allow the removal from the GenoMac-boostrap repo of `install_ssh_agent_dotfiles.sh` and all associated future maintenance of that script. (`install_ssh_agent_dotfiles.sh` essentially replicates what `stow` is designed for.)

## Quick-reference Cheat sheet
(First time here? Please go to the next major heading, viz., “Overview.”)

After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/genomac
git pull origin main
```
## Overview
### Context
This private repository takes off where the public repository [GenoMac-bootstrap](https://github.com/jimratliff/GenoMac-bootstrap/blob/main/README.md) leaves off.

This repo assumes that all of the steps in the [README](https://github.com/jimratliff/GenoMac-bootstrap/blob/main/README.md) 
of the public repository [GenoMac-bootstrap](https://github.com/jimratliff/GenoMac-bootstrap/blob/main/README.md) have been completed. This includes:
- Homebrew and Git are installed
- 1Password and 1Password CLI are installed
- Three dotfiles (sufficient to support using 1Password for SSH authentication to GitHub) are deployed
- 1Password SSH Agent is the default SSH agent for all hosts, including in particular GitHub.
- This repository (viz., GenoMac) has been cloned to GENOMAC_LOCAL_DIRECTORY (`~/genomac`).

### Preview of process
- Use Homebrew to install applications and fonts
  - These installed applications must include GNU Stow
- Install the larger set of dotfiles and implement symlinks in home directory with Stow

## Use Homebrew to install applications and fonts
```shell
cd ~/genomac
make install-via-homebrew
```

## Install larger set of dotfiles and symlink from home directory using GNU Stow
> [!WARNING]
> Currently this dotfile/Stow stuff is focused only on the USER_CONFIGURER user. It will ultimately be expanded to all users.

### Clone the GenoMac-dotfiles directory to GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY
```
make clone-dotfiles
```
### Stow the dotfiles by creating symlinks in the home directory
```
make stow-dotfiles
```
