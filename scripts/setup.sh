# This function will disable WiFi powersaving.
function disable_wifi_powersave {
  wifi_conf="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"

  _log_info "Disabling WiFi powersaving feature."

  if [ -s "$wifi_conf" ]
  then 
    _log_inform "Config file exists and is not empty. Replacing the line."
    sudo sed -i 's/wifi.powersave = [[:digit:]]/wifi.powersave = 2/g' "$wifi_conf" |& _log_trace "(wifi)"
  else
    _log_inform "Config file does not exist, or is empty. Adding necessary lines."
    echo "[connection]
wifi.powersave = 2" | sudo tee -a "$wifi_conf" > /dev/null
  fi

  exit_status=$?
  if [[ $exit_status -eq 0 ]]; then
    _log_success "Done"
  else
    _log_error "Something went wrong while disabling wifi powersaving."
    _log_error "Please see the log file for more details."
  fi
}

# This function will populate .bashrc with some required and useful stuff.
function populate_bashrc {
  _log_info "Modifying .bashrc with recommended additions."

  # Back up current .bashrc just in case.
  if [[ ! -f "$dir/backup/.bashrc" ]]; then
    cd $dir && mkdir backup
    cp ~/.bashrc ./backup/.bashrc
  fi

  # Add a header comment so added lines will be easier to spot.
  num=`cat ~/.bashrc | grep "THIS SECTION WAS ADDED BY EXTERNAL SCRIPT" | wc -l`
  if [ "$num" -lt "1" ]; then
    echo "

# ---------------------------------------------------------------
# ˇˇˇˇˇˇˇˇˇˇ THIS SECTION WAS ADDED BY EXTERNAL SCRIPT ˇˇˇˇˇˇˇˇˇˇ

# ROS WORKSPACES">> ~/.bashrc
  fi

  # Add UAV namespace. Very important for correct functioning of ROS packages.
  num=`cat ~/.bashrc | grep "UAV_NAMESPACE" | wc -l`
  if [ "$num" -lt "1" ]; then
    echo "
# ROS namespace used in all nodes.
export UAV_NAMESPACE=$USER" >> ~/.bashrc
  fi

  # Add useful aliases.
  num=`cat ~/.bashrc | grep "aliases.sh" | wc -l`
  if [ "$num" -lt "1" ]; then

    TEMP=`( cd "$dir/shell_additions" && pwd )`

    echo "
# Useful aliases.
source $TEMP/aliases.sh" >> ~/.bashrc
  fi

  # Add useful shell additions for working with ROS.
  num=`cat ~/.bashrc | grep "shell_scripts.sh" | wc -l`
  if [ "$num" -lt "1" ]; then

    TEMP=`( cd "$dir/shell_additions" && pwd )`

    echo "
# Shell scripts for easier workflows in ROS.
source $TEMP/shell_scripts.sh" >> ~/.bashrc
  fi

  # Add useful git modifications.
  num=`cat ~/.bashrc | grep "git_scripts.sh" | wc -l`
  if [ "$num" -lt "1" ]; then

    TEMP=`( cd "$dir/shell_additions" && pwd )`

    echo "
# Shell scripts for custom Git commands.
source $TEMP/git_scripts.sh" >> ~/.bashrc
  fi

  _log_success "Done"
}

# This function will set up a symbolic link for Pixhawk USB
function usb_setup {
  _log_info "Creating a symbolic link for Pixhawk USB."

  # Check if USB is connected.
  ls /dev/ttyUSB0 > /dev/null 2>&1
  if [ ! $? -eq 0 ] 
  then
    _log_error "Pixhawk USB is not connected!"
    return
  fi

  # Get the information about the USB.
  idVendor=`( udevadm info -a -n /dev/ttyUSB0 |& tee >(_log_trace "(USB)") | grep '{idVendor}' | head -n1 | xargs | grep -oP "==\K.*")`
  exit_status=$?
  idProduct=`( udevadm info -a -n /dev/ttyUSB0 |& tee >(_log_trace "(USB)") | grep '{idProduct}' | head -n1 | xargs | grep -oP "==\K.*")` 
  (( exit_status = exit_status || $? ))
  serial=`( udevadm info -a -n /dev/ttyUSB0 |& tee >(_log_trace "(USB)") | grep '{serial}' | head -n1 | xargs | grep -oP "==\K.*")`
  (( exit_status = exit_status || $? ))

  if [[ $exit_status -ne 0 ]]; then
    _log_error "Something went wrong while getting the info about the USB."
    _log_error "Please see the log file for more details."
    return
  fi

  # Write the configuration to file.
  usb_conf="/etc/udev/rules.d/99-usb-serial.rules"
  if [ -s "$usb_conf" ]
  then 
    _log_warn "/etc/udev/rules.d/99-usb-serial.rules already exists and is not empty! Set USB symlink manually."
  else
    _log_inform "Config file does not exist, or is empty. Adding necessary lines."
    echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$idVendor\", ATTRS{idProduct}==\"$idProduct\", ATTRS{serial}==\"$serial\", SYMLINK+=\"ttyUSB_px4\"" | sudo tee -a "$usb_conf" > /dev/null
  fi

  sudo adduser $USER dialout |& _log_trace "(USB)"

  if [[ $exit_status -ne 0 ]]; then
    _log_error "Something went wrong while adding the user to dialout group."
    _log_error "Please see the log file for more details."
    return
  fi

  _log_dev "System needs to be rebooted for changes to take effect."
  _log_success "Done"
    
}

function workspace_setup {
  _log_info "Creating new catkin workspace."

  # Determine Ubuntu verion and corresponding ROS distribution.
  distro=`lsb_release -r | awk '{ print $2 }'`
  [ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
  [ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

  # Set the name and path of the main workspace.
  WORKSPACE_NAME=larics_ws
  WORKSPACE_PATH=~/WS/$WORKSPACE_NAME
  _log_inform "Workspace path is $WORKSPACE_PATH"

  # If workspace already exists, exit.
  if [[ -d "$WORKSPACE_PATH" ]]; then
    _log_success "Workspace already exists"
    return
  fi

  # Initialize workspace.
  mkdir -p $WORKSPACE_PATH/src
  cd $WORKSPACE_PATH
  source /opt/ros/$ROS_DISTRO/setup.bash
  command catkin init |& _log_trace "(WSP)"

  # Set up catkin build profiles.
  command catkin config --profile debug --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native' -DCMAKE_C_FLAGS='-march=native' |& _log_trace "(WSP)"
  command catkin config --profile release --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native' -DCMAKE_C_FLAGS='-march=native' |& _log_trace "(WSP)"
  command catkin config --profile reldeb --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native' -DCMAKE_C_FLAGS='-march=native' |& _log_trace "(WSP)"

  # Normal installation.
  [ -z "$TRAVIS_CI" ] && command catkin profile set reldeb |& _log_trace "(WSP)"
  # TRAVIS CI build. Set debug for faster build.
  [ ! -z "$TRAVIS_CI" ] && command catkin profile set debug |& _log_trace "(WSP)"

  # Build the workspace.
  command catkin build -c |& _log_trace "(WSP)"

  if [[ $exit_status -ne 0 ]]; then
    _log_error "Something went wrong while configuring catkin workspace."
    _log_and_exit "Please see the log file for more details." "51"
    return
  fi

  # Source ROS files.
  num=`cat ~/.bashrc | grep "$WORKSPACE_PATH" | wc -l`
  if [ "$num" -lt "1" ]; then
    sed -i "\@source /opt/ros/$ROS_DISTRO/setup.bash@a source $WORKSPACE_PATH/devel/setup.bash" ~/.bashrc |& _log_trace "(ROS)"
  fi

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while adding workspace to .bashrc."
    _log_error "Please see the log file for more details."
    _log_dev "Manually add workspace sourcing to .bashrc"
    return
  fi

  _log_success "Done"
}