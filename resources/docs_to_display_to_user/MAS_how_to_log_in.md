# How to log into the Mac App Store
## Why?
In order for GenoMac-system to be able to install an app from the Mac App Store, USER_CONFIGURER needs
to be signed in to the Mac App Store (using the Apple Account that purchased the apps to be installed).
## How frequently must I sign into the Mac App Store?
It’s not clear how long being signed in to the Mac App Store lasts. At this point, GenoMac-system 
treats signing in to the Mac App Store as a one-time bootstrap step.

(If at some point it becomes clear that it is necessary to periodically sign-in again, the Hypervisor can be
refined to use the time it last asked for USER_CONFIGURER to sign into the Mac App Store to determine whether to ask again, or skip.)
