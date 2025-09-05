# GenoMac-system
- [Quick-reference Cheat sheet](#quick-reference-cheat-sheet)
- [Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process)
- [Overview of the GenoMac-system step](#overview-of-the-genomac-system-step)
## Quick-reference Cheat sheet
(First time here? Please go to the next major heading, viz., “[Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process).”)

### Refresh local clone
After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/.genomac-system
git pull origin main
```

### Update apps

NOTE: If revisions to the Brewfile imply installing *new* apps from the Mac App Store, you must sign in to the App Store before executing the below steps.

To update all apps (and install/remove apps as required by any changes in the Brewfile):
```bash
cd ~/.genomac-system
git pull origin main
make app-install-via-homebrew
```

### Reassert systemwide settings
To reassert the systemwide settings (in response to any changes in them in this repo):
```bash
cd ~/.genomac-system
git pull origin main
make prefs-systemwide
```

### Resources (fonts, screensavers, and sounds) are not routinely updated
The systemwide installation of resources (fonts, screensaver, and sounds) is considered a one-time install at the time a new Mac is initially configured. Unlike (a) apps and (b) systemwide preferences, resources are assumed to rarely change. Therefore, `make resources-install` is not designed to be executed routinely but only in response to a known change in an existing deployed resource or a desire to add an additional deployed resource.

If existing resources are updated or new resources are chosen to be added, the corresponding scripts would be modified and re-run for each Mac. (That might imply corresponding changes in user-scoped scripts to point at the new resources.)

If existing resources are marked for deletion, this would require an appropriate `sudo rm -rf path/to/some_resource` to be deployed and executed on each Mac.

## Overview of the entire GenoMac process
Project GenoMac is an implementation of automated setup of multiple Macs, each with multiple users.

We now focus on a particular Mac (rinse and repeat for each Mac). At this point, we assume the following:
- An essentially pristine Mac:
  - Fresh install of macOS
  - Only two users are defined:
    - USER_VANILLA
    - USER_CONFIGURER
  - ***No other configurations or installations have been performed***
- USER_CONFIGURER is signed into its account

At a high level, for a particular new Mac, Project GenoMac involves the following steps:
- USER_CONFIGURER performs the following:
  - manually installs Homebrew (which necessarily installs Git)
  - manually clones the [GenoMac-system repo](https://github.com/jimratliff/GenoMac-system) to `~/.genomac-system`
  - Using the GenoMac-system repo, executes scripts to:
    - make system-level changes to PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications
    - install apps using Homebrew
    - install resources
      - font(s)
      - screensaver(s)
      - sound(s)
    - implement systemwide settings
  - Preparing for the next phase, in which USER_CONFIGURER implements its user-scoped settings, using a script from GenoMac-system, USER_CONFIGURER clones the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - Using the GenoMac-user repo, USER_CONFIGURER executes scripts to:
    - “stow” dotfiles
    - implement generic user-scoped settings
    - configure 1Password for authentication with GitHub
  - USER_CONFIGURER returns to the GenoMac-system repo to create each of the additional users (and the implied additional volumes).
- Loop over each USER_j of the newly created users, USER_j performs the following:
  - USER_j logs into the USER_j account for the first time
  - USER_j clones the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - Using the GenoMac-user repo, USER_j executes scripts to::
    - “stow” dotfiles
    - implement generic user-scoped settings
    - configure 1Password for authentication with GitHub

## Overview of the GenoMac-system step
### Context
This GenoMac-system repository is the first stop in Project GenoMac to setup any of several Macs, each of which has several users.

The GenoMac-system repo is used and cloned exclusively by USER_CONFIGURER. 

GenoMac-system supports implementing configurations at the system level, i.e., configurations that affect all users. These configurations include:
- installing Homebrew (and thereby git)
- installing all CLI and GUI apps (both on or off the Mac App Store)
- installing resources
  - font(s)
  - screensaver(s)
  - sound(s)
- adjusting systemwide settings
  - giving Terminal and iTerm full-disk access
  - modifying systemwide the PATH to give all users access to apps installed by Homebrew
  - setting the ComputerName and LocalHostName
  - setting a login-window message
  - configuring the firewall
  - specifying policies regarding software-update behavior

In addition, GenoMac-system is used by USER_CONFIGURER (a) to *create* new users and (b) when a user’s home directory will reside on a volume that does not exist, to create that volume.

### Preview of process
#### Phase 1
- In Safari, access a pre-defined Google Doc to establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Give Terminal full-disk access
- Install Homebrew (and therefore also Git)
  - Do *not* at this modify PATH to add Homebrew (despite the instructions from the Homebrew installer)
- Clone this public repo to `~/.genomac-system`
- Run a script to modify PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications to the user’s PATH
- Log in to the Mac Apple Store with the Apple Account that purchased the MAS apps to be installed
- Run a script for Homebrew to install applications
- Run a script to install certain resources (font(s), screensaver(s), and sound(s))
- Run a script to implement certain systemwide settings
#### Phase 2
- Clone the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
- Follow the instructions at GenoMac-user to configure the user-scoped settings for USER_CONFIGURER
#### Phase 3
- Return to GenoMac-system to create the additional users and, when necessary, additional volumes to house the user directories for newly created users
#### Phase 4
- Loop over newly created users… performing the steps in the GenoMac-user repo

## Step-by-step implementation
### Make sure you’re logged into the USER_CONFIGURER account
Make sure you’re logged into the USER_CONFIGURER account, *not* into the USER_VANILLA account.
### Establish real-time connection to communicate text back and forth
Open a Google Docs document to be used as/if needed for real-time exchange of text, error messages, etc., between the target Mac and other devices.
- In Safari
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

### Manually install Homebrew
Installing Homebrew will automatically install Xcode Command Line Tools (CLT), the 
installation of which will install, among other things, a version of Git, which will permit cloning this repo.

To install Homebrew, launch Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
(This is the same command as going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)

**Do *not* follow Homebrew’s instructions to modify the PATH. This will be dealt with systemwide later.**

### Clone this repo to `~/.genomac-system`
This public GenoMac-user repo is meant to be cloned locally (using https) to USER_CONFIGURER’s home directory. More specifically, the local directory to which this repo is to be cloned is the hidden directory `~/.genomac-system`, specified by the environment variable $GENOMAC_SYSTEM_LOCAL_DIRECTORY (which is exported by the script `assign_environment_variables.sh`).

Copy the following code block and paste into Terminal:
```shell
mkdir -p ~/.genomac-system
cd ~/.genomac-system
git clone https://github.com/jimratliff/GenoMac-system.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

### Modify PATH
Modify systemwide PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications.
        
Copy the following code block and paste into Terminal:
```shell
cd ~/.genomac-system
make adjust-path
```

**You will be automatically logged out, in order that the new PATH be available for what follows.**

### Log into the Mac App Store
(Note: Needs checking, but presumably the following steps are required only if you’ll be *installing* (rather than merely updating) new apps from the Mac App Store.)

- Launch the Mac App Store
- Log in, using the Apple Account that purchased the MAS apps to be installed by Homebrew

### Use Homebrew to install applications
Copy the following code block and paste into Terminal:
```shell
cd ~/.genomac-system
make app-install-via-homebrew
```

### Install resources (font(s), screensaver(s), and sound(s))
Copy the following code block and paste into Terminal:
```shell
cd ~/.genomac-system
make resources-install
```
This Makefile item combines `make font-install`, `make screensaver-install`, and `sound-install`, which can alternatively be run selectively and separately.

### Implement systemwide settings
Copy the following code block and paste into Terminal:
```bash
cd ~/.genomac-system
make prefs-systemwide
```

### Grant iTerm full-disk access
- System Settings
  - Privacy & Security
    - Scroll down and click Full Disk Access
      - Enable for iTerm

## Clone the GenoMac-user repo for the next step in Project GenoMac
Copy the following command and paste into Terminal:
```shell
make clone-genomac-user
```

## Use GenoMac-user to implement user-scoped settings for USER_CONFIGURER
Go to [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) and follow the instructions. 

After you have finished implementing user-scoped settings for USER_CONFIGURER, return here and pick up the following next step…

## Create new users
[TO BE WRITTEN!]

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


