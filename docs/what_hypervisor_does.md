# What Hypervisor does
- [The Hypervisor keeps track of state across time and within a session#the-hypervisor-keeps-track-of-state-across-time-and-within-a-session)
- [The programmatically implemented settings](#the-programmatically-implemented-settings)

## The Hypervisor keeps track of state across time and within a session
The Hypervisor maintains a memory of *states* in a hidden directory, `~/.genomac-system-state`, which can contain empty files with a `.state` prefix. Each such file corresponds to a particular state identified by the file name (ignoring the `.state` extension) of that state file. If a state’s file exists, the state is true; if the file doesn’t exist, the state if false.

The Hypervisor keeps track of state across time, i.e., whether it has *ever* done a particular operation. This way it ensures that, for some operations, it performs that operation exactly once but no more. Examples of such operations are (a) adjusting the PATH after installing Homebrew and (b) installing a custom alert sound. The state files corresponding to these across-time states all begin the prefix `PERM_`, which stands for “permanent.”[^coerce_migration]

[^coerce_migration]: If such a one-time-only operation should nevertheless be performed again, this can be achieved by deleting the appropriate state file. Then, the next time Hypervisor runs, it will not remember that it had previously performed this operation and will perform it again.

The Hypervisor also keeps track of state within a session, i.e., so that if the session is interrupted (for example, if the Hypervisor tells the user to logout, log back in, and restart the Hypervisor), the Hypervisor will know where to pick back up.[^avoid_infinite_loop] The state files corresponding to these across-time states all begin the prefix `SESH_`, which stands for “session.”[^clear_session_states]

[^avoid_infinite_loop]: Otherwise, the Hypervisor could get caught in an infinite loop of performing an operation, being forced to log out, and rerunning the Hypervisor from the beginning.

[^clear_session_states]: At the end of a session, i.e., when Hypervisor reaches its end, it deletes all of the `SESH_` state files, so that its session memory will start blank the next time Hypervisor is run.

## The programmatically implemented settings

(This is part of the documentation for the [GenoMac-system repository](https://github.com/jimratliff/GenoMac-system).)

(Of course, it’s possible that the below list of steps will become out of sync with the actual state of the Hypervisor’s code. So… trust, but verify!)

Some of the following need to be performed only once, viz., the first time this Hypervisor is run. Thus, some of the following will be skipped over on subsequent Hypervisor runs.

- Updates the local clone of this repo if the local clone is behind the remote
- Configures “split remote” for this repo: Fetch without authentication using HTTPS but push requires SSH
- Ensure that the currently running terminal emulator has Full Disk Access (FDA)
  - If not, the Settings » Privacy & Security » Full Disk Access panel is opened (this terminal app
    should already be pre-populated, but un-enabled, on the list of apps), so the user can simply
    flip the switch for this app.
  - NOTE: This is a potentially interactive step.
- Adjusts PATH for Homebrew and to make `man` pages available to all users (if these steps have not been previously performed)
- Gets the ComputerName and LocalHostName for this Mac, and optionally interactively supply a login-window message (if these steps have not been previously performed)
- Sign into the Mac App Store (if this step has not been previously performed)
  - A document will pop up via QuickLook guiding you through the steps
  - Hypervisor requires that this be done only once. It’s not totally clear to me how long a sign-in to the Mac App Store persists.
- Install Rosetta 2, if desired[^rosetta_installation]
- Installations via Homebrew[^Specifying_Homebrew_installs]<sup>,</sup>[^Homebrew_not_good_for_fonts]
  - CLI programs (“formulae”)
  - GUI apps (“casks”) not from Mac App Store. (You may be asked, *repeatedly* for your password.[^Casks_ask_for_password])<sup>,</sup>[^zoom_is_launched]
  - GUI apps from Mac App Store[^mac_is_homebrew]
- Installations not using Homebrew
  - Apps installed from GitHub releases[^non_homebrew_apps]<sup>,</sup>[^install_github_release]
    - [Alan.app](https://github.com/tylerhall/Alan), crudely highlights the boundary of the current window
    - [utiluti](https://github.com/scriptingosx/utiluti), used by GenoMac-user to specify what app by default should open a double-clicked file of a given type
    - [default_browser_cli](https://github.com/macadmins/default-browser), used by GenoMac-user to set the default browser
  - Resources
    - [Fira Code Nerd Font](https://github.com/ryanoasis/nerd-fonts)[^install_Fira_Code_Nerd_Font]
    - Monroe Williams’ [Matrix Screensaver](https://github.com/monroewilliams/MatrixDownload)[^install_matrix]
    - “Uh oh!” alert sound, is provided locally and installed only the *first time* Hypervisor is run on this Mac, i.e., this is a bootstrap operation.[^alert_sound_provided_locally]
- Implement system-wide settings[^script_systemwide_settings]
  - Disable auto-boot when opening the lid or connecting to power on Apple Silicon laptop
  - Firewall settings: Enable application firewall and enable stealth mode
  - System-update behavior: Don’t automatically update macOS, but *do* update MAS apps and do download macOS updates when available
  - Display additional info (IP address, hostname, OS version) when clicking on the clock digits of the login window
  - Enable Touch ID authentication for sudo
- Clone GenoMac-user to USER_CONFIGURER’s home directory (if it has not already been so cloned)
 
[^Specifying_Homebrew_installs]: The specification of exactly what CLI and GUI apps to install from Homebrew is made in three sub-Brewfile files, all located in `GenoMac-system/homebrew`: (a) `Brewfile.formulae` for CLI programs, (b) `Brewfile.casks` for GUI apps from Homebrew, and (c) `Brewfile.mas` for GUI apps from the Mac App Store.

[^rosetta_installation]: The current version of EagleFiler requires Rosetta 2, which is slated to sunset in macOS 28. EagleFiler is [anticipated to have a fully Apple Silicon–native version by then](https://forum.c-command.com/t/eaglefiler-future-plans-now-that-rosetta-will-be-phased-out-by-macos28/17491/5).

[^Homebrew_not_good_for_fonts]: At least by default, Homebrew installs fonts *only* for the Homebrew user, not for other users. Thus, for Project GenoMac, I have concluded that Homebrew is not an appropriate method to install fonts. There may be workarounds, see e.g., “[Installed font does not show up in Font Book](https://apple.stackexchange.com/questions/478047/installed-font-does-not-show-up-in-font-book),” Ask Different, January 16, 2025; and “[homebrew-cask-fonts for ‘All Users’](https://github.com/orgs/Homebrew/discussions/4138),” Homebrew/discussions, #4138.

[^Casks_ask_for_password]: There are some items whose installation will ask for your sudo password. This occurs for, and only for, some of the casks (but not the formulae nor the Mac App Store apps), in particular: docker-desktop, google-drive, insta360-link-controller, microsoft-teams, and zoom. This password-querying behavior is usually, if not always, associated with casks that are accompanied by some kind of background process, such as an auto-updater.

[^zoom_is_launched]: When Zoom is installed, (a) a dialog box asks “Allow ‘zoom.us’ to find devices on local networks? This process is needed to enable AirPlay and peer-to-peer mettings in Zoom client.” Unlike any other app installed from a Homebrew cask, the act of installing Zoom causes Zoom to be launched.

[^mac_is_homebrew]: It may seem a terminological error to include “GUI apps from Mac App Store” under “Installations via Homebrew.” However, GUI apps from Mac App Store *are* installed by Homebrew, which uses the [mas](https://github.com/mas-cli/mas) CLI tool.

[^non_homebrew_apps]: See the script `GenoMac-system/scripts/installations/non_homebrew/install_non_homebrew_apps.sh`.

[^install_github_release]: The installation of each GitHub release specifies a deliberately chosen “pinned version.” This is the version installed or upgraded to. If the GitHub repo’s latest release shows a version tag different than the pinned version tag, a nonfatal warning is issued as a heads up that maybe you’ll want to update the specification of the pinned version and run Hypervisor again.

[^install_Fira_Code_Nerd_Font]: Although Fira Code Nerd Font is available on Homebrew, Homebrew doesn’t install fonts to be available by all users (i.e., other than the designated Homebrew user). Instead, the latest version of the font is downloaded by GitHub. If that latest version is different from the installed version, the latest version is copied over the installed version.

[^install_matrix]: The Matrix screensaver is installed from GitHub. The installation specifies a deliberately chosen “pinned version.” This is the version installed or upgraded to. If the GitHub repo’s latest release shows a version tag different than the pinned version tag, a nonfatal warning is issued as a heads up that maybe you’ll want to update the specification of the pinned version and run Hypervisor again.

[^alert_sound_provided_locally]: The alert sound is provided in this repo at `GenoMac-system/resources/sounds/alerts/Uh_oh.aiff`. It is treated as a one-time-only bootstrap operation because the sound is not anticipated to change or be updated. 

[^script_systemwide_settings]: See the script `GenoMac-system/scripts/settings/implement_systemwide_settings.sh`.
