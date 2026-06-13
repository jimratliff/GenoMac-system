# Specifying users to spawn

> [!TIP]
> **Related**
> - [The volume, user, and password architecture of Project GenoMac](https://github.com/jimratliff/GenoMac-shared/edit/main/docs/volume_user_password_architecture.md), GenoMac-shared/docs
> - [User attributes](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md), GenoMac-shared/docs
> - [GenoMac-system/scripts/spawn/spawn.sh](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/spawn.sh)

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
    conflicts with any preexisting users.)
- "user-class"
  - a string key, e.g., "superintendent", "personal", "work", "auxiliary"
  - Determines (a) the volume on which the user’s home directory resides and (b) the passphrase that is both (1) the user’s password and (2) the encryption passphrase for the volume.
  - A user class can specify one or more user attributes that will be inherited by default by the users that belong to that user class.
- "avatar" (optional)
  - The terminal subpath to image file for the user’s avatar, e.g., "Betty.png", expressed relative to USER_PICTURE_DIRECTORY.[^user_picture_directory]
  - The user picture at that path is referenced at the time the user account is created, at which point the data from the user picture is incorporated into the user’s profile. The user picture does not need to remain accessible at that path after the user account is created.
- optional additional arbitrary attributes to guide later user provisioning.[^arbitrary_attributes_guide_provisioning] These attributes are *in addition* to any user attributes assigned to the user’s user class. See [User classes and attributes](https://github.com/jimratliff/GenoMac-shared/edit/main/docs/user_classes_and_attributes.md).
 
[^user_picture_directory]: `USER_PICTURE_DIRECTORY="$GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY/Resources/User_pictures"`, where `GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY="${LOCAL_DROPBOX_DIRECTORY}/Preferences_common"`, where `LOCAL_DROPBOX_DIRECTORY="$HOME/Library/CloudStorage/Dropbox"`.

[^arbitrary_attributes_guide_provisioning]: Note that, at the time of user creation, any additional attributes (which by definition aren’t required for creating the user) can’t be stored/recorded in that user’s home directory because that home directory will not exist until it is created at the later time when the user first logs in. Instead, the attribute is recorded as a system-level state file. E.g., a system-level state file "USER_ATTRIBUTE∞§¶wilma¶§∞dropbox§∞¶" would indicate that user "wilma" has the attribute "dropbox". GenoMac-user transfers these system-scoped state files to become user-scoped state files using the function `transfer_system_scoped_user_attribute_states_to_user_scoped`. (Note: `GENOMAC_STATE_USER_ATTRIBUTE_PREFIX="USER_ATTRIBUTE"`.)

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
      "user_class": "work",
      "attributes": [
        "pristine",
        "configurer",
        "emailer",
        "chessplayer",
        "developer"
      ]
    }
  ]
}
```
  
To be clear, "user-class" implies the *volume* of the home directory but the actual path to the home directory is either (a) `Users/some_user` if the home directory resides on the startup volume or (b) `/Volumes/some_volume/Users/some_user` if the home directory resides on the non-startup volume `some_volume`.
See environment variable: `DIRECTORY_CONTAINING_USER_HOME_DIRECTORIES="Users"`
and use `parent_of_users_home_directories()`.
  
A pair of associative arrays maps, respectively, (a) "user-class" to a volume name and (b) "user-class" to a 1password key to securely look up a passphrase.

The volume_name is either (a) `::startup_volume::` (which is not a valid volume name, due to the colons) 
(referenceable with the environment variable STARTUP_VOLUME_SIGNIFIER) or (b) a volume name. When volume_name is `::startup_volume::`, this implies --startup-volume in the sense of parent_of_users_home_directories().

```
  {
    "volume_name_from_user_class": {
      "superintendent": "::startup_volume::",
      "personal": "some_personal_volume",
      "work": "some_work_volume",
      "auxiliary": "some_auxiliary_volume"
    },
    "onepassword_key_from_user_class": {
      "superintendent": "THE_STARTUP_PASSWORD",
      "personal": "PERSONAL_PASSWORD",
      "work": "WORK_PASSWORD",
      "auxiliary": "AUX_PASSWORD"
    },
    "user_attributes_from_user_class": {
      "superintendent": [
        "sysadmin",
        "developer",
        "dropbox"
      ],
      "personal": [
        "dropbox"
      ],
      "work": [
        "dropbox",
        "sync_com",
        "microsoft_word"
      ],
      "auxiliary": [
        "dropbox",
        "sync_com"
      ]
    }
  }
```
