# GenoMac-bootstrap

## TO DO/CONSIDER
Consider moving (a) `make stow-dotfiles` and (b) `clone_genomac_dotfiles_repo.sh` from the GenoMac repo into this repo. This would (a) require `brew install stow` being added here but (b) would allow the removal of `install_ssh_agent_dotfiles.sh` and all associated future maintenance of that script. (`install_ssh_agent_dotfiles.sh` essentially replicates what `stow` is designed for.)

## Quick-reference Cheat sheet
(First time here? Please go to the next major heading, viz., “Overview.”)

After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/bootstrap
git pull origin main
```

To run the better-prefs script:
```bash
cd ~/bootstrap
make better-prefs
```

## Overview
### Context
This public repository is the first stop for configuring a Mac under Project GenoMac.

At this point, we assume the following:
- An essentially pristine Mac:
  - Fresh install of macOS
  - Only two users are defined:
    - USER_VANILLA
    - USER_CONFIGURER
  - ***No other configurations or installations have been performed***
- USER_CONFIGURER is signed into its account
- **An SSH key pair for using my GitHub account/repositories has already been created and stored in the `Dev` vault of my 1Password account, accessible via 1Password on my nearby iPhone.**

### Preview of process
- In Safari, using a Google Sheets doc, establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Install Homebrew (and therefore also Git)
- Modify PATH to add Homebrew
- Clone this public repo to `~/bootstrap`
- Give Terminal full-disk access
- Run a script that executes a bunch of `defaults` commands for USER_CONFIGURER to deal with the most-annoying macOS default settings.
- Prepare USER_CONFIGURER to be able to clone the *next* repo in Project GenoMac, which is private and therefore requires authentication:
  - Install 1Password (using Homebrew)
    - Log into your 1Password account
    - Enable the 1Password SSH Agent
    - Change two settings to ensure the 1Password SSH Agent runs in the background.
  - Install 1Password CLI (using Homebrew)
  - Deploy three dotfiles with `make deploy-ssh-agent-dotfiles`
  - Test the SSH connection to GitHub.
- Clone the *next* repo: viz., GenoMac
- Delete *this* repo: `~/bootstrap`. It is no longer needed.

## Establish real-time connection to communicate text back and forth
Open a Google Docs document to be used as/if needed for real-time exchange of text, error messages, etc., between the target Mac and other devices.
- In Safari, open “Project GenoMac: Text-exchange Document” 
  - In Safari, sign into my standard Google account:
    - Go to google.com and click “Log in”
    - Enter the username of my Google account
    - A QR code will appear. Scan it with my iPhone and complete the authentication.
  - Open the Google Doc document “[Project GenoMac: Text-exchange Document](https://docs.google.com/document/d/1RCbwjLHPidxRJJcvzILKGwtSkKpDrm8dT1fgJxlUdZ4/edit?usp=sharing)]”
 

## Install Homebrew and update PATH
### Install Homebrew
Installing Homebrew will automatically install Xcode Command Line Tools (CLT), the 
installation of which will install a version of Git, which will permit cloning this repo.

To install Homebrew, launch Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
(This is the same command as going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)
### Add Homebrew to PATH
In Terminal, sequentially execute each of the following three commands (it’s supposed to work to copy the entire block and paste as a block into Terminal):
```shell
echo >> /Users/configger/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/configger/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
## Clone this repo to `~/bootstrap`
In Terminal:
```shell
mkdir -p ~/bootstrap
cd ~/bootstrap
git clone https://github.com/jimratliff/GenoMac-bootstrap.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

## Grant Terminal full-disk access
- System Settings
  - Privacy & Security
    - Select the Privacy tab
      - Scroll down and click Full Disk Access
        - Enable for Terminal

## Implement better user preferences
In Terminal, still in `~/bootstrap`:
```shell
make better-prefs
```

Note: This will produce *pages* of terminal output.

## Install and configure 1Password for authentication with GitHub
### Install 1Password and `1Password-CLI`
In Terminal, still in `~/bootstrap`:
```shell
make install-1password
```
This will:
- Install 1Password using Homebrew
- Install 1Password-CLI using Homebrew
- Open/launch 1Password.app

### Log into your 1Password account.
1Password should at this point be the active app. If not, launch it and/or make it active.

Log into my 1Password account.

### Adjust settings of 1Password
Make 1Password active.

#### Make 1Password persistent
In the 1Password app, turn on two checkboxes to ensure that 1Password’s SSH Agent will be live even if the 1Password app itself is closed.
- 1Password » Settings » General
  - ✅ Keep 1Password in the menu bar
  - ✅ Start 1Password at login
 
#### Enable 1Password SSH Agent
Again in the 1Password app:
- 1Password » Settings » Developer:
  - Click on "Setup SSH Agent"
    - SSH Agent
      - ✅ Use the SSH Agent
    - Advanced
      - Remember key approval: **until 1Password quits**
   
## Deploy dotfiles for (a) 1Password SSH agent and (b) SSH client
In Terminal, still in `~/bootstrap`:
```shell
make deploy-ssh-agent-dotfiles
```

## Test the SSH connection with GitHub
```shell
make verify-ssh-agent
```

## Clone the *private* repo GenoMac to `~/genomac`
In Terminal:
```shell
make clone-genomac
```

## Delete the now-obsolete local copy of the repo GenoMac-bootstrap



