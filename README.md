# GenoMac-system
## Quick-reference Cheat sheet
(First time here? Please go to the next major heading, viz., “[Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process).”)

### Refresh local clone
After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/.genomac-system
git pull origin main
```

### Update app and font installation
To update all apps (and install/remove apps as required by any changes in the Brewfile):
```bash
cd ~/.genomac-system
git pull origin main
make install-via-homebrew
```

### Reassert systemwide settings
To reassert the systemwide settings (in response to any changes in them):
```bash
cd ~/.genomac-system
git pull origin main
make system-wide-prefs
```

## Overview of the entire GenoMac process
Project GenoMac is an implementation of automated setup of multiple Macs, each with multiple users.

We now focus on a particular Mac. At this point, we assume the following:
- An essentially pristine Mac:
  - Fresh install of macOS
  - Only two users are defined:
    - USER_VANILLA
    - USER_CONFIGURER
  - ***No other configurations or installations have been performed***
- USER_CONFIGURER is signed into its account

At a high level, for a particular new Mac, Project GenoMac involves the following steps:
- USER_CONFIGURER performs a bootstrapping step and a repeatable/idempotent configuration task:
  - Bootstrapping
    - USER_CONFIGURER manually installs Homebrew (which necessarily installs Git)
    - USER_CONFIGURER manually clones the [GenoMac-system repo](https://github.com/jimratliff/GenoMac-system)
  - Repeatable/idempotent task
    - USER_CONFIGURER executes scripts to implement systemwide settings and installs apps
- USER_CONFIGURER returns to the GenoMac-system repo to create each of the additional users (and the implied additional volumes).
- Loop over each USER_j of the newly created users
  - USER_j logs into the USER_j account for the first time
  - USER_j clones and uses the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to implement the generic user-scope settings for USER_j

## Overview of the GenoMac-system step
### Context
This GenoMac-system repository is the first stop in Project GenoMac to setup any of several Macs, each of which has several users.

The GenoMac-system repo is used and cloned exclusively by USER_CONFIGURER. 

GenoMac-system is responsible for configurations at the system level, i.e., that affect all users. This responsibility includes:
- setting the ComputerName and LocalHostName
- setting a login-window message
- configuring the firewall
- specifying policies regarding software-update behavior
- installing all CLI and GUI apps (both on or off the Mac App Store)

### Preview of process
- In Safari, establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Give Terminal full-disk access
- Install Homebrew (and therefore also Git)
- Modify PATH to add Homebrew
- Clone this public repo to `~/.genomac-system`
- Log in to the Mac Apple Store with the Apple Account that purchased the MAS apps to be installed
- Run a script for Homebrew to install applications and fonts
- Run a script to implement systemwide settings

## Implementation
### Establish real-time connection to communicate text back and forth
Open a Google Docs document to be used as/if needed for real-time exchange of text, error messages, etc., between the target Mac and other devices.
- In Safari
  - open “Project GenoMac: Text-exchange Document” 
  - sign into my standard Google account:
    - Go to google.com and click “Log in”
    - Enter the username of my Google account
    - A QR code will appear. Scan it with my iPhone and complete the authentication.
  - Open the Google Doc document “[Project GenoMac: Text-exchange Document](https://docs.google.com/document/d/1RCbwjLHPidxRJJcvzILKGwtSkKpDrm8dT1fgJxlUdZ4/edit?usp=sharing)]”

### Grant Terminal full-disk access
- System Settings
  - Privacy & Security
    - Scroll down and click Full Disk Access
      - Enable for Terminal

### Install Homebrew and update PATH
#### Manually install Homebrew
Installing Homebrew will automatically install Xcode Command Line Tools (CLT), the 
installation of which will install a version of Git, which will permit cloning this repo.

To install Homebrew, launch Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
(This is the same command as going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)
#### Add Homebrew to PATH
##### New-and-improved to make Homebrew and man pages available to other users without any other user-specific configurations
In Terminal, copy the entire below code block and paste into Terminal (**your password will be required**):
```shell
# --- System-wide Homebrew environment for all zsh login shells ---
# Adds to /etc/zprofile only if not already present.
if [ -x /opt/homebrew/bin/brew ]; then
  if ! sudo grep -q 'BEGIN HOMEBREW shellenv' /etc/zprofile 2>/dev/null; then
    sudo bash -c 'cat >>/etc/zprofile' <<'EOF'
# --- BEGIN HOMEBREW shellenv (system-wide) ---
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# --- END HOMEBREW shellenv (system-wide) ---
EOF
  fi

  # Make Homebrew man pages available to everyone (idempotent)
  # Creates /etc/manpaths.d/homebrew with one line: /opt/homebrew/share/man
  if [ ! -f /etc/manpaths.d/homebrew ] || ! grep -q '^/opt/homebrew/share/man$' /etc/manpaths.d/homebrew 2>/dev/null; then
    printf '/opt/homebrew/share/man\n' | sudo tee /etc/manpaths.d/homebrew >/dev/null
  fi

  # Prime the CURRENT shell session so subsequent commands work now
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew not found at /opt/homebrew. Install it first, then re-run this block." >&2
fi
```
##### Original (per Homebrew itself) but DEPRECATED because it doesn’t put Homebrew in PATH for *other* users
In Terminal, sequentially execute each of the following three commands (it works to copy the entire block and paste as a block into Terminal):
```shell
echo >> /Users/configger/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/configger/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Clone this repo to `~/.genomac-system`
In Terminal:
```shell
mkdir -p ~/.genomac-system
cd ~/.genomac-system
git clone https://github.com/jimratliff/GenoMac-system.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

### Log into the Mac App Store
- Launch the Mac App Store
- Log in, using the Apple Account that purchased the MAS apps to be installed by Homebrew

### Use Homebrew to install applications and fonts
```shell
cd ~/.genomac-system
make install-via-homebrew
```

### Implement systemwide settings
```bash
cd ~/.genomac-system
git pull origin main
make system-wide-prefs
```

## Clone the GenoMac-user repo for the next step in Project GenoMac
In Terminal:
```shell
make clone-genomac-user
```

### Conclusion
At this point, all apps have been installed and all systemwide settings have been configured. There is no need to use this repo again until any of the following occurs:
- the passage of time indicates that apps should be upgraded
  - see [Update app and font installation](#update-app-and-font-installation)
- changes in Brewfile demands that apps/fonts should be added or removed from the Homebrew installation
  - see [Update app and font installation](#update-app-and-font-installation)
- changes in systemwide settings need to be propagated across Macs
  - See [Reassert systemwide settings](#reassert-systemwide-settings)
- a new Mac needs to be configured
  - Go to the top of this repo and start from scratch


Next up: USER_CONFIGURER uses the [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repository to implement generic user-scope settings for USER_CONFIGURER.
