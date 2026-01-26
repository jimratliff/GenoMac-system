# GenoMac-system
- [Quick-reference cheat sheet for occasional maintenance](#quick-reference-cheat-sheet-for-occasional-maintenance)
- [Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process)
- [The four phases of the entire two-repo process](#the-four-phases-of-the-entire-two-repo-process)
- [Overview of the role of the GenoMac-system repository](#overview-of-the-role-of-the-genomac-system-repository)
- [Step-by-step implementation](#step-by-step-implementation)
- [Remaining configuration steps that have not been (cannot be) automated](https://github.com/jimratliff/GenoMac-system/blob/main/README.md#remaining-configuration-steps-that-have-not-been-cannot-be-automated)
- [Apps to install manually](#apps-to-install-manually)
- [Known issues](#known-issues)
- [Dev issues](#appendix-dev-issues)
## Quick-reference cheat sheet for occasional maintenance
(First time here? Please go to the next major heading, viz., “[Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process).”)

WARNING: GRATUITOUS CHANGE TO TRIGGER A NEW COMMIT

### Refresh local clone
After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/.genomac-system
git pull --recurse-submodules origin main
```
(The `--recurse-submodules` ensures that the local version of submodule GenoMac-shared is updated to the commit specified by the GenoMac-user origin repository.)
### Update apps

NOTE: If revisions to the Brewfile imply installing *new* apps from the Mac App Store, you need to be signed in to the App Store before executing the below steps.

To update all apps (and install/remove apps as required by any changes in the Brewfile) after refreshing the local clone:
```bash
cd ~/.genomac-system
git pull origin main
make app-install-via-homebrew
```

### Install apps/tools not available in Homebrew
Some apps are not available in Homebrew but are available as downloads from GitHub repositories (e.g., Alan.app and the CLI tools `default-browser` and `utiluti`.

Unlike Homebrew installations, upgrading to new versions is not automatic. Instead, each app is “pinned” to a particular version. This script will detect, and report, when the GitHub repo has a newer version available (relative to the pinned version), but it requires a manual change in the corresponding script to update the pinned version. In this sense, this script is intended to be run only (a) on a new system or (b) after one or more the apps/tools has been updated. That said, running this script is idempotent; there is no harm in running it repeatedly.
```shell
cd ~/.genomac-system
make app-install-other-than-homebrew
```

### Reassert systemwide settings
To reassert the systemwide settings (in response to any changes in them in this repo) after refreshing the local clone:
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
- Systemwide settings, performed by USER_CONFIGURER
  - manually install Homebrew (which necessarily installs Git)
  - manually clone the [GenoMac-system repo](https://github.com/jimratliff/GenoMac-system) to `~/.genomac-system`
  - using the GenoMac-system repo, execute scripts to:
    - make system-level changes to PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications
    - install apps using Homebrew
    - install non-Homebrew apps (e.g., that can be downloaded from a GitHub repository)
    - install resources
      - font(s)
      - screensaver(s)
      - sound(s)
    - implement systemwide settings
- User-scoped settings for USER_CONFIGURER performed by USER_CONFIGURER
  - using a script from GenoMac-system, clone the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - using the GenoMac-user repo, USER_CONFIGURER executes scripts to:
    - “stow” dotfiles
    - implement generic user-scoped settings
    - configure 1Password for authentication with GitHub
- USER_CONFIGURER returns to the GenoMac-system repo to create each of the additional users (and the implied additional volumes).
- Loop over each USER_j of the newly created users, USER_j performs the following:
  - USER_j logs into the USER_j account for the first time
  - USER_j clones the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - using the GenoMac-user repo, USER_j executes scripts to::
    - “stow” dotfiles
    - implement generic user-scoped settings
    - configure 1Password for authentication with GitHub
   
## The four phases of the entire two-repo process
### Phase 1
- In Safari, access a pre-defined Google Doc to establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Give Terminal full-disk access
- Install Homebrew (and therefore also Git)
  - Do *not* at this modify PATH to add Homebrew (despite the instructions from the Homebrew installer)
- Clone this public repo to `~/.genomac-system`
- Run a script to modify PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications to the user’s PATH
- Log in to the Mac Apple Store (MAS) with the Apple Account that purchased the MAS apps to be installed
- Run a script for Homebrew to install applications
- Run a script to install certain resources (font(s), screensaver(s), and sound(s))
- Run a script to implement certain systemwide settings
### Phase 2
- Clone the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
- Follow the instructions at GenoMac-user to configure the user-scoped settings for USER_CONFIGURER
### Phase 3
- Return to GenoMac-system to create the additional users and, when necessary, additional volumes to house the user directories for newly created users
### Phase 4
- Loop over newly created users… performing the steps in the GenoMac-user repo

## Overview of the role of the GenoMac-system repository
### Context
This GenoMac-system repository is the first stop in Project GenoMac to setup any of several Macs, each of which has several users.

The GenoMac-system repo is used and cloned exclusively by USER_CONFIGURER. 

GenoMac-system supports implementing configurations at the system level, i.e., configurations that affect all users. These configurations include:
- installing Homebrew (and thereby git)
- installing all CLI and GUI apps (both on or off the Mac App Store)
- install non-Homebrew apps (e.g., that can be downloaded from a GitHub repository)
- installing resources
  - font(s)
  - screensaver(s)
  - sound(s)
- adjusting systemwide settings
  - giving Terminal and iTerm full-disk access;
  - giving iTerm ability to control System Events (in order to run AppleScript)
  - modifying systemwide the PATH to give all users access to apps installed by Homebrew
  - setting the ComputerName and LocalHostName
  - setting a login-window message
  - configuring the firewall
  - specifying policies regarding software-update behavior

In addition—in a separate, later step, GenoMac-system is used by USER_CONFIGURER (a) to *create* new users and (b) when a user’s home directory will reside on a volume that does not exist, to create that volume.

The current repo is used in conjunction with the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-system), which (a) is cloned by each user (including USER_CONFIGURER) and (b) is responsible for configurations at the user level.

GenoMac-system also relies (as does GenoMac-user) on the [GenoMac-shared repository](https://github.com/jimratliff/GenoMac-shared). GenoMac-shared is an externally defined set of common code that specifies some environment variables and defines some helper functions. This common code is incorporated into each of GenoMac-system and GenoMac-user as a submodule located at `external/genomac-shared` of each of the two container repositories. (See GenoMac-shared’s [README](https://github.com/jimratliff/GenoMac-shared/blob/main/README.md) for information on how that affects/complicates work flows, particularly when there is a change to GenoMac-shared’s code.)
### The Makefile is the user’s interface with the functionality of this repo

The `Makefile` provides the interface for the user to effect the functionalities of this repo, such as commanding the execution of (a) installing apps via Homebrew and (b) changing certain systemwide macOS settings using `defaults write` commands.

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
(This is the same command as you would get by going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)

**Do *not* follow Homebrew’s instructions to modify the PATH. This will be dealt with systemwide later.**

### Clone this repo to `~/.genomac-system`
This public GenoMac-user repo is meant to be cloned locally (using https) to USER_CONFIGURER’s home directory.[^https] 
More specifically, the local directory to which this repo is to be cloned is the hidden directory `~/.genomac-system`, specified by the environment variable $GENOMAC_SYSTEM_LOCAL_DIRECTORY (which is exported by the script `assign_environment_variables.sh`).

[^https]: After having cloned the repository via https, GitHub will not let you edit the repo from the CLI (but will from the browser). In order to edit
the repo from the CLI, you would need to change the repo from https to SSH, which can be done via 
`git remote set-url origin git@github.com:OWNER/REPOSITORY.git`. (Use `git remote -v` to clarify the syntax for your repo.)

Copy the following code block and paste into Terminal:
```shell
mkdir -p ~/.genomac-system
cd ~/.genomac-system
git clone --recurse-submodules https://github.com/jimratliff/GenoMac-system.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

(The `--recurse-submodules` flag exists because this repo has a submodule ([GenoMac-shared](https://github.com/jimratliff/GenoMac-shared). The `--recurse-submodules` ensures that the submodule’s code is also cloned, not just a pointer to it.)

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

Note: There are some items whose installation will ask for your sudo password. This occurs for, and only for, some of the casks (but not the formulae nor the Mac App Store apps), in particular:
- docker-desktop
- google-drive
- insta360-link-controller
- microsoft-teams
- zoom

This password-querying behavior is usually, if not always, associated with casks that are accompanied by some kind of background process, such as an auto-updater.

### Install app(s) not in Homebrew (e.g., from a GitHub repo)
Copy the following code block and paste into Terminal:
```shell
cd ~/.genomac-system
make app-install-other-than-homebrew
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

### Grant iTerm (a) full-disk access and (c) ability to control computer
- System Settings
  - Privacy & Security
    - Accessibility
      - Add for iTerm
    - Full Disk Access
      - Enable for iTerm

Note: The Accessibility setting is meant to address the dialog box that can pop up: “‘iTerm.app’ wants access to control ‘System Events.app’,’ which arises because the scripts I run want to use AppleScript.

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
 
## Remaining configuration steps that have not been (cannot be) automated

### Apps to install manually
- Howard Oakley’s [Podofyllin: lightweight PDF viewer and analysis](https://eclecticlight.co/delighted-podofyllin/)
  - [version 1.4](https://eclecticlight.co/wp-content/uploads/2025/06/podofyllin14.zip)

## Known issues
- The test for existence of Homebrew assumes an Apple Silicon Mac rather than an Intel Mac. See:
  - `crash_if_homebrew_not_installed` in GenoMac-shared/scripts/helpers-apps.sh and, in particular, its
    reliance on the location `/opt/homebrew/bin/brew`.
  - `adjust_path_for_homebrew` in GenoMac-system/scripts/prefs_scripts/adjust_path_for_homebrew.sh
- Defining a separate lockscreen.png (i.e., separate from a user’s wallpaper) is not working.
  - The previously known technique is given by Sodiq Olanrewaju, “[How to Change Your Mac’s Lock Screen Background Image](https://www.switchingtomac.com/how-to-change-your-macs-lock-screen-background-image/),” Switching2Mac.com, February 14, 2024.
  - Anticipating being able to implement this in macOS 26 Tahoe, I added to this repo: resources/images/lockedscreen.png
    - If and until this is resolved, this file is vestigial.
   
## Appendix: Dev issues
The preceding content of this README focuses on the “user” experience, i.e., the experience from USER_CONFIGURER’s experience, as a consumer of the repository in its contemperaneous state.

In contrast, the present appendix addresses issues about how this repo can be changed and those changes propagated and used by USER_CONFIGURER (even if USER_CONFIGURER is the entity making those changes).

### Configure the GitHub remote to use SSH for pushing from local to GitHub
This repo is public so that it can be easily cloned at the beginning of setting up a Mac (way before 1Password and its SSH agent get set up). But, ultimately, the configuring user will want to make changes to the repo, and this requires being able to authenticate with GitHub.

Since GitHub doesn’t authenticate in the CLI via HTTPS, the repo needs to be configured so that it can be modified locally and pushed to GitHub, which requires SSH. Although the repo could be configured to require SSH for both fetch and push, that would require authentication even to fetch, which is a needless hassle.

Thus, we instead configure separate URLs for fetch and push:
```
cd ~/.genomac-system

# Set the fetch URL to HTTPS (no auth needed for public repo)
git remote set-url origin https://github.com/jimratliff/GenoMac-system.git

# Set the push URL to SSH (uses 1Password SSH agent)
git remote set-url --push origin git@github.com:jimratliff/GenoMac-system.git
```

### Incorporating the GenoMac-shared repo as a submodule
#### To add GenoMac-shared as a submodule of GenoMac-user
```
cd ~/.genomac-system
git submodule add https://github.com/jimratliff/GenoMac-shared.git external/genomac-shared
git commit -m "Add genomac-shared submodule"
git push origin main
```
#### For the consumer
For the consumer of GenoMac-system (and indirectly of GenoMac-shared), updating the local clone of GenoMac-system is done via:
```
cd ~/.genomac-system
git pull --recurse-submodules origin main
```
which can also be performed by `make refresh-repo`.
#### For the developer of GenoMac-system and GenoMac-shared
When a change is made to GenoMac-shared, and therefore when there is a new commit to GenoMac-shared, that new commit will not automatically be reflected in the submodule of GenoMac-system.

To ensure that the latest commit of GenoMac-shared is reflected in the submodule of GenoMac-user, the following process is performed:
```
cd ~/.genomac-system
# Updates parent repo and checks out the *pinned* submodule commits
git pull --recurse-submodules origin main
# Fetches the submodule's *latest* commit from its remote (not just what's pinned)
git submodule update --remote
# Stages the new submodule commit reference
git add external/genomac-shared
# Commits only if there's actually a change
git diff --cached --quiet external/genomac-shared || git commit -m "Update genomac-shared submodule"
# Pushes the updated submodule reference
git push origin main
```
which can also be performed by `make dev-update-repo-and-submodule`.
