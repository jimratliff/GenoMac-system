# User spawning requires a GitHub Personal Access Token (PAT) to access the GenoMac-private repo

The user-spawning process gets crucial specifications about the users to be created (including the user’s names, user class, uid,
attributes, avatar, volume to house the user’s home directory).

These specifications are obtained securely by Hypervisor-system from the configuring user’s 1Password account. Specifically,
the configuring user is assumed to have (a) a 1Password vault named "GenoMac-user-creation" (actually, "$OP_VAULT_FOR_GENOMAC_USER_CREATION")
and within that vault a 1Password item "GitHub_PAT_GenoMac-private_read-only" (actually, "$OP_ITEM_NAME_GENOMAC_PRIVATE_GITHUB_PAT"),
both variables of which are defined in `GenoMac-shared/scripts/assign_common_environment_variables.sh`.

This PAT can be (and should be) a *fine-grained* PAT, rather than a “classic” PAT. It should be specific to the GenoMac-private repo. 
It should grant only the following permissions:
- Contents: Read-only
- Metadata: Read-only (automatically included)
