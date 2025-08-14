# GenoMac-system
## Overview
### Context
This GenoMac-system repository is the first stop in Project GenoMac to setup any of several Macs, each of which has several users. 

The GenoMac-system repo is cloned exclusively by USER_CONFIGURER. 

GenoMac-system is responsible for configurations at the system level, i.e., that affect all users. This responsibility includes, among other things, installing all CLI and GUI apps (both on or off the Mac App Store).

This repository is complementary to the [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repository, which is focused on generic user-specific settings. The GenoMac-user repo is used:
- by USER_CONFIGURER as part of the GenoMac-system process
- separately by each other user

### Preview of process
- In Safari, using a Google Sheets doc, establish a real-time textual connection to other devices to be used as/if needed for real-time exchange of text, error messages, etc.
- Give Terminal full-disk access
- Install Homebrew (and therefore also Git)
- Modify PATH to add Homebrew
- Clone this public repo to `~/genomac-system`
- Use Homebrew to install applications and fonts
- Detour to GenoMac-user
    - Clone the public repo [GenoMac-user](https://github.com/jimratliff/GenoMac-user) to `~/.genomac-user`.
    - `cd ~/.genomac-user`
    - “Stow” the “dot files”
    - Implement the initial set of macOS preferences
- Return to GenoMac-system: `cd ~/genomac-system`
