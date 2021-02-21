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

  _log_info "Please enter GitHub credentials"
  git config --global user.name "$USER"
  git config --global user.email "kopterworx.$USER@air.com"
  git config --global credential.helper 'cache --timeout 3600'
  read -p    "Username: " g_username
  read -s -p "Password: " g_password
  echo
  echo "protocol=https
host=github.com
username=$g_username
password=$g_password

" | git credential approve
  
  _log_success "Successfully stored GitHub credentials"


  local after_effects_core_dependencies=(wget whiptail ping ps grep cut tr awk)
  _check_dependencies "${after_effects_core_dependencies[@]}"

  _init_script_variables;

  _init_print_basic_info;

  # I don't like when someone else is occupying my room
  # Test if any apt-get ops are running
  _test_conflicting_apps;

  # Did I tell you that I need to call My friends over internet?
  _test_internet_connection;
# -------------------------------------------------------------------


# ------------------------- SYSTEM SETUP ----------------------------
  _log_stage "Setting up the system"

  # Disable WiFi power saving.
  disable_wifi_powersave;

  # Populate .basrhc.
  populate_bashrc;

  # Set up symbolic links for Pixhawk USB port.
  usb_setup;
# -------------------------------------------------------------------


# ------------------------ INSTALLATION -----------------------------
  _log_stage "Installation"

  # Suppress console output.
  DEBIAN_FRONTEND=noninteractive

  # Install essentials.
  install_essentials;

  # Install ROS.
  install_ros;

  # Install general dependencies.
  install_general;

  # Install tools.
  install_tools;

  # Install gitman.
  install_gitman;
# -------------------------------------------------------------------


# ----------------------- CONFIGURING ROS ---------------------------
  _log_stage "Configuring ROS"

  # Create new catkin workspace.
  workspace_setup;

  # Install ROS packages.
  install_packages;

# -------------------------------------------------------------------


# --------------------------- FINALIZE ------------------------------  
  _log_stage "All steps completed"
  end_time=`date +%s`          # End time of the script.
  runtime=$((end_time-start_time))  # Script duration.
  runtime_m=$( printf %02d $(( (runtime % 3600) / 60 )) )
  runtime_s=$( printf %02d $(( (runtime % 3600) % 60 )) )
  _log_success "Runtime: $runtime_m:$runtime_s (mm:ss)"
# -------------------------------------------------------------------


# --------------------------- CLEAN UP ------------------------------
  trap "kill 0" EXIT
  cleanup;

  _log_cleanup "Autoremoving unnecessary apt packages."
  sudo apt-get autoremove -y |& _log_trace "(FIN)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong in apt autoremove."
    _log_error "Please see the log file for more details."
  fi
# -------------------------------------------------------------------


# ---------------------------- REBOOT -------------------------------
  _log_warn "Please reboot the system to complete the setup."
  _log_info "Do you want to reboot now?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) sudo reboot; break;;
        No ) _log_dev "Remember to source setup files (source ~/.bashrc)."; exit 0;;
    esac
  done
# -------------------------------------------------------------------
}

main