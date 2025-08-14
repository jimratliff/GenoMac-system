# GenoMac-system
## Overview of the entire GenoMac process
Project GenoMac is an implementation of automated setup of multiple Macs, each with multiple users.

At this point, we assume the following:
- An essentially pristine Mac:
  - Fresh install of macOS
  - Only two users are defined:
    - USER_VANILLA
    - USER_CONFIGURER
  - ***No other configurations or installations have been performed***
- USER_CONFIGURER is signed into its account

At a high level, for a particular new Mac, Project GenoMac involves the following steps:
- USER_CONFIGURER clones the [GenoMac-system repo](https://github.com/jimratliff/GenoMac-system) and implements systemwide settings and installs apps
- USER_CONFIGURER clones the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to implement the generic user-scope settings for USER_CONFIGURER
- USER_CONFIGURER clones the [GenoMac-spawn repo](https://github.com/jimratliff/GenoMac-spawn) to create each of the additional users.
- Loop over each USER_j of the newly created users
  - USER_j logs into the USER_j account for the first time
  - USER_j clones the [GenoMac-user repo](https://github.com/jimratliff/GenoMac-user) to implement the generic user-scope settings for USER_CONFIGURER

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
- Establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Give Terminal full-disk access
- Install Homebrew (and therefore also Git)
- Modify PATH to add Homebrew
- Clone this public repo to `~/genomac-system`
- Use Homebrew to install applications and fonts
- Implement systemwide settings

## Implementation
### Establish real-time connection to communicate text back and forth
Open a Google Docs document to be used as/if needed for real-time exchange of text, error messages, etc., between the target Mac and other devices.
- In Safari, open “Project GenoMac: Text-exchange Document” 
  - In Safari, sign into my standard Google account:
    - Go to google.com and click “Log in”
    - Enter the username of my Google account
    - A QR code will appear. Scan it with my iPhone and complete the authentication.
  - Open the Google Doc document “[Project GenoMac: Text-exchange Document](https://docs.google.com/document/d/1RCbwjLHPidxRJJcvzILKGwtSkKpDrm8dT1fgJxlUdZ4/edit?usp=sharing)]”

### Grant Terminal full-disk access
- System Settings
  - Privacy & Security
    - Select the Privacy tab
      - Scroll down and click Full Disk Access
        - Enable for Terminal

### Install Homebrew and update PATH
#### Install Homebrew
Installing Homebrew will automatically install Xcode Command Line Tools (CLT), the 
installation of which will install a version of Git, which will permit cloning this repo.

To install Homebrew, launch Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
(This is the same command as going to [brew.sh](https://brew.sh/) and copying the command from near the top of the page under “Install Homebrew.”)
#### Add Homebrew to PATH
In Terminal, sequentially execute each of the following three commands (it’s supposed to work to copy the entire block and paste as a block into Terminal):
```shell
echo >> /Users/configger/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/configger/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
### Clone this repo to `~/genomac-system`
In Terminal:
```shell
mkdir -p ~/genomac-system
cd ~/genomac-system
git clone https://github.com/jimratliff/GenoMac-system.git .
```
**Note the trailing “.” at the end of the `git clone` command.**

### Use Homebrew to install applications and fonts
```shell
cd ~/genomac-system
make install-via-homebrew
```

### Conclusion
At this point, all systemwide settings have been configured. There is no need to use this repo again until (a) a new Mac needs to be configured or (b) a change or addition in systemwide settings needs to be propagated across Macs.

Next up: For each user, USER_CONFIGURER included, use the [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repository to implement generic user-scope settings for that user.