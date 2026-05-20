# About spawning new users for this Mac
## The volume, user, and password architecture of Project GenoMac
### High-level overview
We focus on a particular Mac.[^multiple_macs]

[^multiple_macs]: Project GenoMac does consider multiple Macs in the following context: Each Mac is approximately a replica of the other Macs including the set of users. The idea is not multiple Macs, each used by a separate person than each other Mac but rather the same person operates all the Macs. Although each Mac has multiple “users” in the macOS sense, all of those users are typically the same human.

There is (a) the startup volume (protected by File Vault) and (b) other, independently encrypted (non-startup and non–File Vault) volumes.

There are two major groups of users:
- infrastructural/utility users: These users exists only to help manage the Mac itself. Their home directories reside on the startup volume and don’t contain highly sensitive information. These users all have Secure Tokens for the File Vault–protected startup volume and hence can mount the startup volume.
- substantive users: These are the important users who do important things. Each substantive user has a home directory that resides on an independently encrypted volume other than the startup volume.

Substantive users need to know *two* sets of credentials: (a) their own, of course, but also (b) the credentials for one of the infrastructual/utility users—in order to be able to boot the Mac into the infrastructural/utility user’s account, from which to mount the volume where the substantive user’s home directory resides.

The process for a substantive user to boot the Mac and log into its account:
- Boot the Mac
- Log in as any of the infrastructural/utility users. This mounts the startup volume.
- A dialog box will be presented for each other (non-startup volume), offering to take the passphrase for that volume and mount it.
- Enter the passphrase for the volume on which this substantive user has their home directory. (Note that, by design, this passphrase is the same as the account password for this substantive user.) Decline the dialog boxes for all other volumes.
- Log out of the infrastructual/utility user’s account, returning to the login window.
- Log into the substantive user’s account (using the same passphrase as was used to mount this non-startup volume.

- Each user belongs to a user class.
- Each user class is assigned a volume (on which the user’s home directory resides).
- Each volume is assigned a passphrase.
- Every user must know the credentials for an “infrastructure user,” i.e., one whose home directory resides on the startup volume, in order that, at boot, the user
### Volumes
- Let V be the set of volumes
- V = {v<sup>†</sup> , v<sub>1</sub>, v<sub>2</sub>, …}, where v<sup>†</sup> is the startup volume, and each v<sub>i</sub> is a distinct non–startup volume.
- Each volume v∈V has a unique passphrase v.p.[^unique_password_for_volume]
- For each *non-startup* volume v∈V\\{v<sup>†</sup>}, v is encrypted (*not* using File Vault) using passphrase v.p.
- The *startup* volume v<sup>†</sup> is encrypted using File Vault.[^file_vault_mounted_by]
### Users
  - Let U be the set of users
  - User classes
    - Let U<sup>§</sup> be the set of user classes such that U<sup>§</sup>={U<sub>1</sub>, U<sub>2</sub>, … , U<sub>n</sub>} partitions U.
    - Each user class U<sub>i</sub> is assigned a unique volume U<sub>i</sub>.v.[^unique_volume]
    - Each user class U<sub>i</sub> is assigned a unique passphrase[^unique_password_for_user_class] U<sub>i</sub>.p via inheritance from the user class’s volume
      - ∀U<sub>i</sub>∈U<sup>§</sup>, U<sub>i</sub>.p=(U<sub>i</sub>.v).p
  - Each user u is assigned (a) a volume u.v and (b) a passphrase u.p by inheritance from the user’s user class
    - ∀U<sub>i</sub>∈U<sup>§</sup>, ∀u∈U<sub>i</sub>
      - u.v=U<sub>i</sub>.v
        - The volume u.v is the volume that contains the user’s home directory
      - u.p=U<sub>i</sub>.p
        - The passphrase u.p serves both as (a) the passphrase by which the user can decrypt/mount the volume u.v that contains the user’s home directory and (b) the password by which the user logs into the user’s account.
 
[^unique_password_for_volume]: ∀v,v′∈V, (v≠v′) ⇒ (v.p≠v′.p.)

[^file_vault_mounted_by]: The startup volume will be mounted when any user with a Secure Token for that volume logs in.

[^unique_volume]: ∀U<sub>i</sub>,U<sub>j</sub>∈U<sup>§</sup>, (U<sub>i</sub>≠U<sub>j</sub>) ⇒ (U<sub>i</sub>.v≠U<sub>j</sub>.v).

[^unique_password_for_user_class]: ∀U<sub>i</sub>,U<sub>j</sub>∈U<sup>§</sup>, (U<sub>i</sub>≠U<sub>j</sub>) ⇒ (U<sub>i</sub>.p≠U<sub>j</sub>.p).

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
