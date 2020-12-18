# NUC setup instructions and scripts for LARICS UAVs

NOTE: At the moment, only PX4 autopilot is supported.

## How to run it?
Either clone this repository to the home folder on NUC or copy it from USB memory drive. Then execute the main script:
```bash
git clone https://github.com/larics/uav_nuc_setup.git
cd uav_nuc_setup
./px4_setup.sh
```

## What will it do?
**1. Ask for superuser password.**  
The script as a whole does not require root privileges, but some parts of it do. Therefore, you need to enter the password at the beginning and it will be cached until the end of the installation procedure.

**2. Ask for GitHub credentials.**  
Some ROS packages are in private repositories so you need proper credentials to clone them. In order to be "fire and forget", the script asks the user to enter this information at the beginning. Credentials are then stored in cache for 1 hour or until the script finishes. Because of the way this is implemented, you must enter the correct credentials or the script will fail when it tries to clone repositories in question. Any member of the LARICS Staff team should be able to access them.

**3. Set up basic Git information in global config file.**  
-`user.name` is set to the name of the uav - e.g. hawk1  
-`user.email` is set to an imaginary address in form of - e.g. kopterworx.hawk1@air.com  
-`credential.helper` is set to `cache` - When user enters credential for access to remote repositories, git will not ask for them for 15 minutes.

**4. Check for apt/dpkg locks and internet connection.**  

**5. Disable WiFi powersaving feature.**  
This is done to prevent connectivity loss in critical situations. The script will write the following to `/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`:
```
[connection]
wifi.powersave = 2
```

**6. Create a backup of the default .bashrc in "backup" folder.**

**7. Add following things to the .bashrc:**
   - Sourcing of ROS and the custom workspace
   - Useful aliases (look [here](shell_additions/aliases.sh))
   - Useful shell additions (look [here](shell_additions/shell_scripts.sh))
   - Custom git commands (look [here](shell_additions/git_commands.sh))
   
**8. Symlink Pixhawk USB.**  
As described [here](https://dev.px4.io/v1.11/en/companion_computer/pixhawk_companion.html#software-setup-on-linux).

**9. Install essential programs, tools and dependencies.**  
This includes upgrading all currently installed packages and installing things like wget, curl, zip, etc.

**10. Install ROS.**  
This includes adding ROS repositories and keys, installing dependencies, base version of ROS and most common packages, and initializing rosdep.

**11. Install general packages.**  
This includes things like build tools, Python packages, and general libraries.

**10. Install various tools and utilities.**  
This includes things like ranger, htop, tmux, nmap, net-tools, openssh etc.

**11. Install gitman.**  
Gitman is used for managing git repositories.

**12. Create a new catkin workspace.**  
This workspace will be placed in `home` folder and is named `larics_ws`. Only the basic, common packages essential for a functioning UAV should be placed here. When developing and testing new packages, users should create their own workspaces and set up [workspace overlaying](http://wiki.ros.org/catkin/Tutorials/workspace_overlaying).

**13. Download and build all of the essential packages for UAVs.**  
Gitman is used for this step.

**14. Clean up after itself.**  
Git credential menager's cache is erased and cache timeout is set to 15 minutes. Apt will autoremove any unneccessary packages.  
Cleanup is executed even in the event of abnormal script termination.

## But how can I be sure it really did all of these things?
Check the latest log in "logs" folder.

## What if something goes wrong?
Check the latest log in "logs" folder and look for errors. If you can resolve it, great! Just fix whatever needs to be fixed and run the script again. Steps that were executed successfully will not be executed again. If you can't resolve it on your own, send the latest log file to marko.krizmancic@fer.hr. 

If you think something is missing or fundamentaly wrong, open an issue on GitHub or do it yourself and push :)