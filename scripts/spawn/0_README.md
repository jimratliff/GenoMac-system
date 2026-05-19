# About spawning new users for this Mac

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
- "avatar" (optional)
  - Relative path to image file for the user’s avatar, e.g., "Betty.png"
  - The path is expressed relative to USER_PICTURE_DIRECTORY
    - Hint: USER_PICTURE_DIRECTORY="$GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY/Resources/User_pictures"

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
