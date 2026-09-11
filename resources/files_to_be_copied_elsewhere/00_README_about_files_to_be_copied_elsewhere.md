# About the directory `files_to_be_copied_elsewhere`

> [!NOTE]
> This is the one file in this directory that is *not* intended to be copied elsewhere!

This directory holds files that are meant to be copied elsewhere by either (a) a script or (b) a human acting manually.

## Guide to the files in this directory
- `spawn`
  - This is a directory of files to be used as templates and then copied to `GenoMac-private/spawn`.[^WHY_HERE_RATHER_THAN_IN_PRIVATE]
  - `specs-of-users-to-create.json`
    - This is a *template* for USER_CONFIGURER (a) to adapt/modify for their particular set of users and (b) manually copy to `GenoMac-private/spawn`.


[^WHY_HERE_RATHER_THAN_IN_PRIVATE]: These template files are included here in the public repo GenoMac-system in order that users of GenoMac-system will have exemplars of the files necessary to include in their own GenoMac-private repo (since outside users won’t be able to see the original GenoMac-private, since it’s private 😉.)
