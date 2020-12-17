function _check_dependencies()
{
  #Checks if commands in array are available.
  # Accepts one argument as array.
  local dependencies=("$@")
  local dependency_check_failed_count dep_res dependency
  dependency_check_failed_count=0;
  _log_info "Checking dependencies..."
  for dependency in "${dependencies[@]}"; do
   command -v "$dependency" > /dev/null
   dep_res=$?
   if [ "$dep_res" -eq 1 ]; then
     _log_error "$dependency is not installed!${NC}"
     dependency_check_failed_count=$((dependency_check_failed_count+1))
   fi
  done

  if [ "$dependency_check_failed_count" -gt 0 ]; then
    _log_error "One or more dependencies not installed."
    _log_and_exit "Sorry! $SCRIPT cannot continue!" "1"
  fi
}

function _test_internet_connection ()
{
  # Function to check internet connection
  _log_info "Checking connectivity"
  if sudo wget --tries=5 --timeout=2 "$PING_URL" -O /tmp/ae/testinternet &>/dev/null 2>&1; then
    sudo rm -f /tmp/ae/testinternet
    _log_success "Connected!"
  else
    _log_error "You are not connected to the Internet!. "
    _log_error "Please check your Internet connection and try again."
    sudo rm -f /tmp/ae/testinternet || _log_debug "Failed to remove temp network connectivity resp file"
    _log_and_exit "No internet connection!" "14"
  fi
}


function _test_conflicting_apps ()
{
  # Function checks if any apps like syanptic aptitude are running.
  local lock
  _log_info "Check for conflicting apps..."
  for lock in synaptic update-manager software-center apt-get dpkg aptitude
  do
    # shellcheck disable=SC2009
    if ps -U root -u root u | grep $lock | grep -v grep > /dev/null; then
      _log_and_exit "Installation won't work. Please close $lock first then try again." "15"
    else
      _log_debug "$lock is not running."
     fi
   done
   _log_success "No conflicts detected."
}