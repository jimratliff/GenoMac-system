# About spawning new users for this Mac
## The volume, user, and password architecture of Project GenoMac
- Let V be the set of volumes
- V = {v<sup>*</sup>, v* ,v<sub>1</sub>, v<sub>2</sub>, …}



  - a startup volume, encrypted using File Vault
  - perhaps multiple other volumes, each encrypted (not part of File Vault) with an encryption passphrase.
 



- There are multiple users
- Each user has a home directory, which can reside either (a) on the startup volume or (b) a different volume.
  - The startup volume is referenced distinctly from other volumes in the sense that the startup volume is not referenced by name but rather by the environment variable `STARTUP_VOLUME_SIGNIFIER="::startup_volume::"`.[^why_startup_is_different]
- Each user has a user password
- Because a user’s password is also intended to be the encyrption password for the volume on which the user’s home directory resides, for a given volume V, all users whose home directory resides on V must share a common password P.

[^why_startup_is_different]: This distinction in how a startup volume is referenced vis-à-vis how another volume is referenced arises because the path to a home directory on the startup volume is `/Users/some_user`, whereas the path to a home directory on another volume is `/Volumes/some_volume/Users/some_user`. Thus, the path to a user home directory on the startup volume doesn’t explicitly reference the volume name of the startup volume.

Project GenoMac defines multiple user-classes.
- A user-class includes all users, and only those users, that share both (a) a common user password and (b) a common volume for the users home directories.

## Specification of users to be created
### `users_to_create`
Each user to be created is specified by:
- "short_name"
  - a string, e.g., "Betty")
- "full_name" (optional)
  - a string, e.g., "Betty Rubble")
- "uid"
  - the user’s ID, in the range 510–999, which macOS uses to distinguish users (rather than by user name)
  - (Project GenoMac excludes IDs 501–509 here, even though they are legit user IDs, in order to prevent
    conflicts with preexisting users.)
- "user-class"
  - a string key, e.g., "simple_admin", "implementor", "unsullied", "personal", "work", "auxiliary"
  - Determines (a) the user’s password and (b) the volume on which the user’s home directory resides.
  - 
    - The current structure doesn’t permit the home directories of users of a given user-class to be split over multiple volumes. This result could be achieved by splitting a user-class (e.g., into "personal-1", "personal-2", etc.) such that the newly split classes mapped to a common password but to different volumes.
- "avatar" (optional)
  - Terminal subpath to image file for the user’s avatar, e.g., "Betty.png" expressed relative to
    USER_PICTURE_DIRECTORY="$GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY/Resources/User_pictures"
  - The user picture at that path is referenced at the time the user account is created, at which point the data from the user picture is incorporated into the user’s profile. The user picture does not need to remain accessible at that path after the user account is created.

```
  {
    "users_to_create": [
      {
        "short_name": "betty",
        "full_name": "Betty Rubble",
        "uid": 511,
        "user_class": "personal",
        "avatar": "Betty.png"
      },
      {
        "short_name": "wilma",
        "full_name": "Wilma Flintstone",
        "uid": 512,
        "user_class": "work"
      }
    ]
  }
```
  
To be clear, "user-class" implies the *volume* of the home directory but the actual path to the home directory
is `some_volume/Users/some_user`.
See environment variable: DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES="Users"
and use parent_of_users_home_directories_from_volume_name()
  
A separate configuration file maps (a) "user-class" to a volume key, (b) volume key to a 1password key to securely
look up a passphrase, and (c) volume key to a volume name.

The volume_name is either (a) `::startup_volume::` (which is not a valid volume name, due to the colons) 
(referenceable with the environment variable STARTUP_VOLUME_SIGNIFIER) or
(b) a volume name. When volume_name is `::startup_volume::`, this implies --startup-volume in the sense of parent_of_users_home_directories().

```
  {
    "volume_key_from_user_class": {
      "simple_admin": "startup_volume",
      "implementor": "startup_volume",
      "unsullied": "startup_volume",
      "personal": "personal_volume",
      "work": "work_volume",
      "auxiliary": "auxiliary_volume"
    },
    "onepassword_key_for_passphrase_from_volume_key": {
      "startup_volume": "THE_STARTUP_PASSWORD",
      "personal_volume": "PERSONAL_PASSWORD",
      "work_volume": "WORK_PASSWORD",
      "auxiliary_volume": "AUX_PASSWORD"
    },
    "volume_name_from_volume_key": {
      "startup_volume": "::startup_volume::",
      "personal_volume": "Volume_for_Personal_Users",
      "work_volume": "Volume_for_Work_Users",
      "auxiliary_volume": "Volume_for_Auxiliary_Users"
    },
  }
```
