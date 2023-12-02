#!/bin/bash

readonly AE_EXEC_START=$(date +%s)
readonly SCRIPT=$(basename "$0")

# Get Hostname
readonly CLIENT_NAME=$(hostname)

# etc sources list dir
readonly SOURCES_FILE_DIR=/etc/apt/sources.list.d

# Ping URL
readonly PING_URL="www.google.com"

case "${DEBUG}" in
  1 | "yes" | "true" | "TRUE")     AE_DEBUG=1;set -o pipefail;;
  "ci" | "CI")                     AE_DEBUG=2;set -eo pipefail;;
  2 | "trace")                     AE_DEBUG=2;set -o pipefail;;
  *)                               AE_DEBUG=0;set -o pipefail;;
esac

# SCRIPT METADATA
readonly dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
readonly REL_NAME="6.1.0-RC1"
readonly REL_NUM=610

# Include functions used in the rest of the script.
source ./include/log_functions.sh
source ./include/checks_tests.sh
source ./include/actions.sh

source ./scripts/setup.sh
source ./scripts/installation.sh


function main {
  _init_printf_variables

  trap "exit" INT TERM
  trap "cleanup; kill 0" EXIT


# --------------- INITIALIZATION AND PRE-RUN CHECKS -----------------
  printf "${STAGE_COLOR}✈ Initializing & running checks${NC}\n"

  _init_logging
  start_time=`date +%s` # Start time of the script.

  _log_info "Permission checks"
  # We don't want the entire script to run as root because some commands need to be executed by the user.
  # User is prompted for password and then this command is run in the background, refreshing the sudo
  # privileges each minute without prompting. When the script exits, this will also be terminated.
  # https://serverfault.com/a/833888
  sudo -v || exit $?
  sleep 1
  while true; do 
    sleep 60
    sudo -nv
  done 2>/dev/null &
  _log_success "Got root privileges"  


  local after_effects_core_dependencies=(wget whiptail ping ps grep cut tr awk)
  _check_dependencies "${after_effects_core_dependencies[@]}"

  _init_script_variables;

  _init_print_basic_info;

  # I don't like when someone else is occupying my room
  # Test if any apt-get ops are running
  _test_conflicting_apps;

  # Did I tell you that I need to call My friends over internet?
  _test_internet_connection;
  
  
  # Disable WiFi power saving.
  disable_wifi_powersave;
  # Set performance mode for Ubuntu 22.04
  powerprofilesctl set performance

  # Disable automatic updates.
  disable_automatic_updates;

  # Modify /etc/hosts.
  modify_etc_hosts;
  
  # Install essentials
  install_essentials;
  
  # Install tools
  install_tools;
  
  # Install docker
  ./scripts/docker.sh
  
  # Add user to groups
  sudo usermod -a -G dialout,tty,bluetooth,docker $USER
  
  # Pull uav_ros_stack docker for easier
  docker pull lmark1/uav_ros_stack:focal
  
  # Increase swap size to 32GB
  sudo swapoff -a
  sudo fallocate -l 32G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
}

main
