# GenoMac-system
Project GenoMac automates setup and maintenance of multiple Macs, each with multiple users.[^multiple_users] The current repository (GenoMac-system) is one of three repositories in Project GenoMac. It addresses system-level configuration of each Mac. The other two repositories are: (a) [GenoMac-user](https://github.com/jimratliff/GenoMac-user), which addresses user-level configuration of each user, and (b) [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared), which provides shared code used by both GenoMac-system and GenoMac-user.[^genomac_shared_purpose] (There is an additional, private repo, too: [GenoMac-private](https://github.com/jimratliff/GenoMac-private). Its purpose is TBD.)

[^multiple_users]: The envisioned case is: there is a set of users and each Mac has all (or almost all) of those users. In other words, this is a scenario of a set of users residing on each of several Macs.

[^genomac_shared_purpose]: GenoMac-shared is an externally defined set of common code that specifies some environment variables and defines some helper functions. This common code is incorporated into each of GenoMac-system and GenoMac-user as a submodule located at `external/genomac-shared` of each of the two container repositories. See GenoMac-shared’s [README](https://github.com/jimratliff/GenoMac-shared/blob/main/README.md) for information on how that affects/complicates work flows, particularly when there is a change to GenoMac-shared’s code.

Both the GenoMac-system and GenoMac-user repositories are intended to be cloned locally, in order to provide access to the necessary scripts and other resources:
- GenoMac-system is cloned only by the designated configuring user, USER_CONFIGURER, for that Mac.
- GenoMac-user is cloned separately by *each user*.

GenoMac-user assumes that the Mac has already been configured using GenoMac-system.

Note that **USER_CONFIGURER is the *only* user authorized to use Homebrew** to install applications (or update them, unless they have auto-upgrade mechanisms).[^HOMEBREW_IN_MULTIUSER_ENVIRONMENT]<sup>,</sup>[^HOMEBREW_UPDATE_IS_DIFFERENT]

[^HOMEBREW_IN_MULTIUSER_ENVIRONMENT]: Homebrew wasn’t designed to be used in a multiuser environment. (Homebrew states explicitly “Homebrew is primarily designed for single-user use and does not work well in multi-user configurations.” (E.g., see the FAQs “[Why does Homebrew say sudo is bad?](https://docs.brew.sh/FAQ#why-does-homebrew-say-sudo-is-bad)” and “[What is the default ownership and permissions used by Homebrew?](https://docs.brew.sh/FAQ#what-is-the-default-ownership-and-permissions-used-by-homebrew).” In prior versions, the first of these two FAQs added “If you need to run Homebrew in a multi-user environment, consider creating a separate user account specifically for use of Homebrew,” but this language is no longer there as of March 12, 2026.) However, satisfactory use of Homebrew in a multiuser environment can be achieved by having a dedicated user for using Homebrew. (See “[The solution is simple. Because Homebrew is not designed to be used by multiple users, and it’s not designed to be installed anywhere else than the default location, what you want to do instead is to install Homebrew in its default location with a dedicated user that you switch to in order to use it](https://www.codejam.info/2021/11/homebrew-multi-user.html#:~:text=The%20solution%20is%20simple%2E%20Because%20Homebrew%20is%20not%20designed%20to%20be%20used%20by%20multiple%20users%2C%20and%20it%E2%80%99s%20not%20designed%20to%20be%20installed%20anywhere%20else%20than%20the%20default%20location%2C%20what%20you%20want%20to%20do%20instead%20is%20to%20install%20Homebrew%20in%20its%20default%20location%20with%20a%20dedicated%20user%20that%20you%20switch%20to%20in%20order%20to%20use%20it%2E),” in Valérian Galliat, “Using Homebrew on a multi-user system (don’t),” Codejam, November 17, 2021.) The only problem I have identified that might be attributable to using Homebrew in this way was trying to use Homebrew’s version of `zsh` in accounts other than the Homebrew user. My workaround is (a) *not* to install Homebrew’s `zsh` and to instead use the `zsh` that comes by default in macOS and (b) not to install Homebrew’s `zsh-autocomplete`.

[^HOMEBREW_UPDATE_IS_DIFFERENT]: While Homebrew will typically attempt to update all CLI applications, Homebrew will not attempt to update GUI apps that have their own auto-updating mechanisms. Thus, users other than USER_CONFIGURER may be asked to accept an app’s auto-updating prompt. (See (a) “[Many applications update themselves, so their casks are ignored by `brew outdated` and `brew upgrade`. This behaviour can be overridden by adding `--greedy` to either command](https://github.com/Homebrew/homebrew-cask/blob/master/USAGE.md#:~:text=Many%20applications%20update%20themselves%2C%20so%20their%20casks%20are%20ignored%20by%20brew%20outdated%20and%20brew%20upgrade%2E%20This%20behaviour%20can%20be%20overridden%20by%20adding%20%2D%2Dgreedy%20to%20either%20command%2E)” and (b) “[Why aren’t some apps included during `brew upgrade`?](https://docs.brew.sh/FAQ#why-arent-some-apps-included-during-brew-upgrade),” Homebrew Documentation » FAQs.)

If you are *not* USER_CONFIGURER, and USER_CONFIGURER has already configured this Mac, go directly to [GenoMac-user](https://github.com/jimratliff/GenoMac-user) to set up your account on this Mac.

If you *are* USER_CONFIGURER and:
- you’re unfamiliar with Project GenoMac, start with [Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process)
- you’re familiar with Project GenoMac and:
  - you’re beginning to set up a particular Mac, start with [Step-by-step: Set up a new Mac](#step-by-step-set-up-a-new-mac)
  - you’ve already set up this particular Mac once, go to [Maintaining the Mac’s system-scoped settings by periodically re-running the Hypervisor](#maintaining-the-macs-system-scoped-settings-by-periodically-re-running-the-hypervisor)

## Table of contents
- [Overview of the entire GenoMac process](#overview-of-the-entire-genomac-process)
- [Step-by-step: Set up a new Mac](#step-by-step-set-up-a-new-mac)
- [Maintaining the Mac’s system-scoped settings by periodically re-running the Hypervisor](#maintaining-the-macs-system-scoped-settings-by-periodically-re-running-the-hypervisor)
- [Known issues](#known-issues)
- [Dev issues](#appendix-dev-issues)

**Other documentation files**
- [What Hypervisor does and what settings/configurations it implements](https://github.com/jimratliff/GenoMac-user/blob/main/docs/what_hypervisor_does.md)
- At GenoMac-user:
  - [Determining the `defaults write` commands that correspond to desired changes in settings](https://github.com/jimratliff/GenoMac-user/blob/main/docs/defaults_detective.md)
- At GenoMac-shared:
  - [The two types of operations in Project GenoMac and their corresponding families of states](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/States_migration_operations.md)
  - [Dev issues common to both GenoMac-system and GenoMac-user](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/shared_dev_issues.md)
  - [The scope of declarativeness in Project GenoMac](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/declaritiveness.md)


## Overview of the entire GenoMac process
Project GenoMac automates setup and maintenance of multiple Macs, each Mac having multiple users. We now focus on a particular Mac (rinse and repeat for each Mac). At this point, we assume the following:
- An essentially pristine Mac:
  - Fresh install of macOS
  - Only two users are defined, both of which are administrators, referred to as USER_VANILLA and USER_CONFIGURER.
  - FileVault has been enabled.
  - ***No other configurations or installations have been performed***
- USER_CONFIGURER is signed into its account

At a high level, for a particular new Mac, the initial bootstrapping function of Project GenoMac involves the following steps:
- Systemwide configuration, performed by USER_CONFIGURER
  - manually install Homebrew (which necessarily installs Git, allowing cloning this repository)
  - manually clone this GenoMac-system repo to `~/.genomac-system`
  - using the GenoMac-system repo, run a script, referred to as the Hypervisor, which performs the following, largely autonomously but requiring some interaction at various steps:
    - makes system-level changes to PATH to make Homebrew-installed apps and man pages available to all users without user-specific modifications
    - installations
      - apps (CLI and GUI) using Homebrew
      - apps from the Mac App Store
      - third-party apps not available via Homebrew (e.g., that can be downloaded from a GitHub repository)
      - other resources: a font, a screensaver, and an alert sound
    - implement systemwide settings (e.g., policies regarding firewall and macOS system-update behavior)
- User-scoped settings for USER_CONFIGURER performed by USER_CONFIGURER
  - using a script from GenoMac-system, clone the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - using the GenoMac-user repo, USER_CONFIGURER executes a script, also referred to as the Hypervisor, to *inter alia*:
    - “stow” dotfiles
    - implement generic user-scoped macOS settings
    - implement customized preferences for native and third-party applications
    - configure 1Password for authentication with GitHub
    - establish syncing with Dropbox, as a source of shared configuration data and other resources, as well as general-purpose file syncing.
- USER_CONFIGURER returns to the GenoMac-system repo to use a script to create each of the additional users (and the implied additional volumes).
- The human configurer then loops over each USER_j of the newly created users, performing the following:
  - Log into the USER_j account for the first time
  - Clone the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`
  - Runs the GenoMac-user Hypervisor to perform the same user-scoped configurations that USER_CONFIGURER performed, described above.
 
After the above initial bootstrapping, each of GenoMac-system and GenoMac-user uses its respective Hypervisor to maintain the system and users, respectively:
- USER_CONFIGURER periodically runs the GenoMac-system Hypervisor to (a) to update apps and install/remove any apps that have been added/removed from the specified lists of desired Homebrew apps and (b) to re-implement and/or implement any desired changes in system-scoped preferences.
- Every user periodically runs the GenoMac-user Hypervisor to re-implement and/or implement any desired changes in user-scoped preferences.

## Step-by-step: Set up a new Mac

- [The initial bootstrapping GenoMac-system process](#the-initial-bootstrapping-genomac-system-process)
- [Configure USER_CONFIGURER’s user-scoped settings using GenoMac-user](#configure-user_configurers-user-scoped-settings-using-genomac-user)
- [USER_CONFIGURER creates the new users that will reside on this Mac]([#create-the-new-users-that-will-reside-on-this-mac](#user_configurer-creates-the-new-users-that-will-reside-on-this-mac))
- [Each new user logs into its account and uses GenoMac-user to configure itself](#each-new-user-logs-into-its-account-and-uses-genomac-user-to-configure-itself)

### The initial bootstrapping GenoMac-system process
- [Make sure you’re logged into the USER_CONFIGURER account](#make-sure-youre-logged-into-the-user_configurer-account)
- [Establish shared textual connection to communicate text back and forth with other devices](#establish-shared-textual-connection-to-communicate-text-back-and-forth-with-other-devices)
- [Grant Terminal full-disk access and then launch it](#grant-terminal-full-disk-access-and-then-launch-it)
- [Manually install Homebrew](#manually-install-homebrew)
- [Clone this repo to `~/.genomac-system`](#clone-this-repo-to-genomac-system)
- [Iteratively run the Hypervisor until completion](#iteratively-run-the-hypervisor-until-completion)
#### Make sure you’re logged into the USER_CONFIGURER account
Make sure you’re logged into the USER_CONFIGURER account, *not* into the USER_VANILLA account.
#### Establish shared textual connection to communicate text back and forth with other devices
Open a Google Docs document to be used as/if needed for real-time exchange of text, error messages, etc., between the target Mac and other devices.
- In Safari
  - sign into my standard Google account:
    - Visit google.com and click “Log in”
    - Enter the username of my Google account
    - A QR code will appear. Scan it with my iPhone and complete the authentication.
  - Open the Google Doc document “[Project GenoMac: Text-exchange Document](https://docs.google.com/document/d/1RCbwjLHPidxRJJcvzILKGwtSkKpDrm8dT1fgJxlUdZ4/edit?usp=sharing)]”[^my_google_doc]
 
[^my_google_doc]: Of course, this document is specific to, and accessible by, only me. Make your own!

#### Grant Terminal full-disk access and then launch it
Because the Mac is pristine when beginning this GenoMac-system bootstrapping process the first time, the macOS-supplied Terminal is the only terminal-emulator application available. We’ll use it until the Hypervisor has installed third-party apps, at which point I switch iTerm.

Terminal will need full-disk access:
- System Settings
  - Privacy & Security
    - Scroll down and click Full Disk Access
      - Hit “+”
      - In the Open dialog box, find Terminal (e.g., ⇧⌘U to reach /Applications/Utilities, then find Terminal)
      - Enable for Terminal
- Launch Terminal

#### Manually install Homebrew
We can’t even clone this repository at this point, because Git doesn’t come out-of-the-box on macOS. We’ll need Homebrew eventually to perform app installations. We install Homebrew now, because doing so has the side benefit that installing Homebrew will automatically install Xcode Command Line Tools (CLT), the 
installation of which will install, among other things, a version of Git, which will permit cloning this repo.

To install Homebrew, launch Terminal and paste in the following code snippet:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
(This is the same command as you would get by going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)

**Do *not* follow Homebrew’s instructions to modify the PATH. This will be dealt with systemwide later.**

#### Clone this repo to `~/.genomac-system`
This public GenoMac-user repo is meant to be cloned locally (using https) to USER_CONFIGURER’s home directory.[^https] 
More specifically, the local directory to which this repo is to be cloned is the hidden directory `~/.genomac-system`.[^hidden_dir_env_var]

[^hidden_dir_env_var]: This directory is specified by the environment variable $GENOMAC_SYSTEM_LOCAL_DIRECTORY (which is exported by the script `assign_environment_variables.sh`).

[^https]: After having cloned the repository via https, GitHub will not let you edit the repo from the CLI (but will from the browser). In order to edit
the repo from the CLI, you would need to change the repo from https to SSH, which can be done via 
`make dev-configure-remote-for-https-fetch-and-ssh-push` or, once `just` has been installed, by `just dev-configure-remote-for-https-fetch-and-ssh-push`. Typically, we defer this step—that configures the local clone for editing—until after both (a) the initial system configuration has been performed and (b) USER_CONFIGURER has configured its own user-scoped settings using GenoMac-user. At that point, 1Password has been configured to authenticate GitHub using SSH. A consequence of this delay is that, should a problem arise that requires a change in GenoMac-system’s code, the change should be made on another computer and pushed to GitHub. At that point, USER_CONFIGURER here can refresh the local clone with `make refresh-repo` or, once `just` is installed with `just refresh-repo`. Both of these commands are shorthand for `git pull --recurse-submodules origin main`.

Copy the following code block and paste into Terminal:
```shell
mkdir -p ~/.genomac-system
cd ~/.genomac-system
git clone --recurse-submodules https://github.com/jimratliff/GenoMac-system.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

(The `--recurse-submodules` flag exists because this repo has a submodule (viz., [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared)). The `--recurse-submodules` ensures that the submodule’s code is also cloned, not just a pointer to it.)

#### Iteratively run the Hypervisor until completion
The Hypervisor is a scripting system that manages the system-scoped configuration of the Mac, both (a) for the initial bootstrap and (b) for periodic maintenance.[^Hypervisor_scripts]

[^Hypervisor_scripts]: The entry point to the Hypervisor script is `GenoMac-system/scripts/hypervisor/hypervisor.sh`, which calls, for most of the detailed work, `GenoMac-system/scripts/hypervisor/subdermis.sh`

The Hypervisor is run the first time by:[^homebrew_via_just]
```
cd ~/.genomac-system
make run-hypervisor
```

[^homebrew_via_just]: The first time Hypervisor is run, it uses Homebrew to install many apps/programs, including in particular `just`. At that point, you can use `just` commands instead of the somewhat-less user-friendly `make` commands. In particular, you can then run the Hypervisor with `just run-hypervisor`. The [just command](https://github.com/casey/just) is a “command runner” or “a handy way to save and run project-specific commands.” It is a modern successor to the [make command](https://man7.org/linux/man-pages/man1/make.1.html).

When Hypervisor is first launched during a session, it will check automatically for updates to this repo. If any are found, Hypervisor will refresh this repo and relaunch the Hypervisor.

At some early point in the first run of Hypervisor (perhaps immediately after being asked to supply a Computer Name), a dialog box will pop up: “‘Terminal’ wants access to control ‘System Events’. Allowing control will provide access to documents and data in ‘SYstem Events’, and to perform actions within that app.” It will then offer buttons: “Don’t Allow” and “Allow”. Click “Allow”.

At certain points in the process, within a single Hypervisor session, the Hypervisor will encourage/prompt the user to logout of the user account to help incorporate the changes so far. When you log in after the logout, simply start the Hypervisor again (type the following into terminal: `make run-hypervisor`). The Hypervisor keeps track of its state, and it will restart where you last left off. Keep logging back in, after each logout, and running `make run-hypervisor` until you see “TTFN,” signaling completion of the full Hypervisor session:
```
 _____  _____  _____  _   _  _
|_   _||_   _||  ___|| \ | || |
  | |    | |  | |_   |  \| || |
  | |    | |  |  _|  | |\  ||_|
  |_|    |_|  |_|    |_| \_|(_)


ℹ️  You will be logged out semi-automatically to fully internalize all the work we’ve done.

✅ No GenoMac warnings or failures detected in this run.
```
The Hypervisor produces a *lot* of output, typically many screenfulls. If an important warning is issued, the Hypervisor keeps track of it and redisplays it when it reaches a standard stopping point (either when it urges you to logout or when it completes the entire configuration). If no warnings were detected, the Hypervisor will state that explicitly:
```
✅ No GenoMac warnings or failures detected in this run.
```

By collecting any warnings and repeating them at the end, you’re relieved of the necessity of wading through all of the output to look for anomalies.

Also note that the Hypervisor runs under `set -euo pipefail`, which is designed to make everything come to a crashing halt if there is any error. Thus, it tries to protect you against silent failures that you wouldn’t notice.

### Configure USER_CONFIGURER’s user-scoped settings using GenoMac-user
At this point, the Mac is largely setup at a system-scoped level, but USER_CONFIGURER is still very primitive as a *user*: all user-interface settings are at their out-of-the-box defaults. We fix that by using GenoMac-user to configure USER_CONFIGURER’s user-scoped settings.

The Hypervisor (the one belonging to GenoMac-system) you’ve already run should have, as its final step, clone the GenoMac-user repository to the `~/.genomac-user` directory in USER_CONFIGURER’s home directory.

Now visit [the README from GenoMac-user](https://github.com/jimratliff/GenoMac-user/blob/main/README.md) and follow its instructions to set up USER_CONFIGURER’s user-scoped settings. 

When finished with that process, return here to finish the remainder of the system-scoped setup: Creating new users.

### USER_CONFIGURER creates the new users that will reside on this Mac

**WORK IN PROGRESS**

### Each new user logs into its account and uses GenoMac-user to configure itself

At this point, you loop through each new user account and:
- Sign into the user’s account. This creates that user’s home directory (on whatever volume it was specified to reside)
- Run GenoMac-user’s Hypervisor on that user account to configure the user-scoped settings.

## Maintaining the Mac’s system-scoped settings by periodically re-running the Hypervisor
At this point, all apps have been installed and all systemwide settings have been configured. There is no need to use this repo again on this Mac until any of the following occurs:
- the passage of time indicates that apps should be upgraded
- changes in the Brewfile’s sub-Brewfiles, or any other installation-related code in GenoMac-system, demands that apps/fonts should be added or removed from the Homebrew installation
- changes in systemwide settings need to be propagated across Macs

In any of the above cases, all you need to do is to rerun the Hypervisor:
```
cd ~/.genomac-system
just run-hypervisor
```


## Appendices



### A note on the declarativeness, or lack thereof, of non-Homebrew installations by Hypervisor
Unlike Homebrew installations, upgrading to new versions is not automatic. Instead, some non-Homebrew apps are “pinned” to a particular version (viz., Alan.app, default-browser, .and utiluti). Hypervisor will detect, and report, when the GitHub repo has a newer version available (relative to the pinned version), but it requires a manual change in the corresponding script to update the pinned version. In this sense, this script is intended to be run only (a) on a new system or (b) after one or more the apps/tools has been updated.

If existing resources are marked for deletion, this would require an appropriate `sudo rm -rf path/to/some_resource` to be deployed and executed on each Mac.



### `make` vs. `just`

### Refresh local clone

**TODO: (a) move this to "quick-reference sheet for occasional maintenance" and (b) explain that this can be done with make and just refresh-repo**

After initial cloning, to pull down subsequent changes to this repository
```bash
cd ~/.genomac-system
git pull --recurse-submodules origin main
```
(The `--recurse-submodules` ensures that the local version of submodule GenoMac-shared is updated to the commit specified by the GenoMac-user origin repository.)








### The Makefile is the user’s interface with the functionality of this repo

The `Makefile` provides the interface for the user to effect the functionalities of this repo, such as commanding the execution of (a) installing apps via Homebrew and (b) changing certain systemwide macOS settings using `defaults write` commands.















 




## Known issues
- Assumption of an Apple Silicon Mac rather than an Intel Mac:
  - `adjust_path_for_homebrew` in GenoMac-system/scripts/prefs_scripts/adjust_path_for_homebrew.sh
- Defining a separate lockscreen.png (i.e., separate from a user’s wallpaper) is not working.
  - The previously known technique is given by Sodiq Olanrewaju, “[How to Change Your Mac’s Lock Screen Background Image](https://www.switchingtomac.com/how-to-change-your-macs-lock-screen-background-image/),” Switching2Mac.com, February 14, 2024.
  - Anticipating being able to implement this in macOS 26 Tahoe, I added to this repo: resources/images/lockedscreen.png
    - If and until this is resolved, this file is vestigial.
- Zsh and autocompletion issues
  - At some early stage, I encountered problems getting zsh-autocomplete to work, so I removed it and use only zsh-autosuggestions.
  - This may be related to:
    - I don’t install zsh from Homebrew, using the macOS built-in zsh instead. Homebrew’s zsh appeared to cause trouble for users other than the user that installed Homebrew. (Homebrew doesn’t always adopt the perspective of a multi-user environment.)
    - https://github.com/casey/just?tab=readme-ov-file#what-are-the-idiosyncrasies-of-make-that-just-avoids:~:text=them%2E-,macOS
      - If you use Homebrew to install `just`, it will automatically install the most recent copy of the zsh completion script in the Homebrew zsh
      directory, which the built-in version of zsh doesn't know about by default. It's best to use this copy of the script if possible, since it will
      be updated whenever you update `just` via Homebrew. Also, many other Homebrew packages use the same location for completion scripts, and the built
      in zsh doesn't know about those either. To take advantage of `just` completion in zsh in this scenario, you can set `fpath` to the Homebrew
      location before calling `compinit`
- EagleFiler currently requires Rosetta 2, although EagleFiler’s developer is working on an Apple Silicon–native version of EagleFiler anticipated to be ready for macOS 28, which is when Rosetta 2 sunsets. Hypervisor optionally installs Rosetta 2. This will either need to be removed for macOS 28, or the version of macOS will need to be checked, or, perhaps, the attempted installation would just fail silently.
- TODOs
  - Globally rename:
    - `test_genomac_user_state` to `test_user_state`
    - `set_genomac_user_state` to `set_user_state`
    - `delete_genomac_user_state` to `delete_user_state`
    - `test_genomac_system_state` to `test_system_state`
    - `set_genomac_system_state` to `set_system_state`
    - `_set_state_based_on_yes_no` to `_determine_state_based_on_yes_no`
   
## Dev issues
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
