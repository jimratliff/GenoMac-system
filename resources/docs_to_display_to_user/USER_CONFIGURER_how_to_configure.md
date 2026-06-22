# You must now use the GenoMac-user repo to configure this user account
## Summary
You have gone as far as you can go with GenoMac-system on this account with this user account unconfigured. You must now use a different repository, GenoMac-user, to fully configure this user account.

After you finish configuring this account, you will return to GenoMac-system to complete the system-scoped configuration of this Mac.

## Use GenoMac-user to configure this user account
The Hypervisor of GenoMac-system has already cloned GenoMac-user to your home directory at `~/.genomac-user`, so GenoMac-user is ready for you to use.

- [Open GenoMac-user’s README in a browser](https://github.com/jimratliff/GenoMac-user/blob/main/README.md)
- Open a new terminal window
- In the terminal, navigate to the local clone of GenoMac-user:
  - `cd ~/.genomac-user`
- Repeatedly run the Hypervisor of GenoMac-user until it completes:
  - `just run-hypervisor`
 
Keep rerunning the Hypervisor until you see:
```
 _____  _____  _____  _   _  _
|_   _||_   _||  ___|| \ | || |
  | |    | |  | |_   |  \| || |
  | |    | |  |  _|  | |\  ||_|
  |_|    |_|  |_|    |_| \_|(_)


ℹ️  You will be logged out semi-automatically to fully internalize all the work we’ve done.
   Please log back in.
   To restart, re-execute just run-hypervisor and we’ll pick up where we left off.

✅ No GenoMac warnings or failures detected in this run.
```
