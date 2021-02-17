function _init_printf_variables()
{
  #Initialize printf variables
  readonly       _phase_repo="(REPO)"
  readonly        _phase_ppa="(PPA)"
  readonly    _phase_install="(INST)"
  readonly      _phase_purge="(PURGE)"
  readonly        _phase_deb="(DPKG)"
  readonly        _phase_apt="(APT)"
  readonly    _phase_apt_key="(KEYS)"
  readonly        _phase_pip="(PIP)"
  readonly       _phase_snap="(SNAP)"

  # Log Premitives
  readonly       _info="[INF]"
  readonly        _dev="[DEV]"
  readonly      _debug="[DBG]"
  readonly    _cleanup="[DEL]"
  readonly    _success="[ OK]"
  readonly       _warn="[WRN]"
  readonly      _error="[ERR]"
  readonly   _variable="[VAR]"
  readonly       _crit="[CRT]"


  #colors for display
  readonly YELLOW=$'\e[38;5;220m'
  readonly GREEN=$'\e[32m'
  readonly ORANGE=$'\e[38;5;209m'
  readonly RED=$'\e[31m'
  readonly BLUE=$'\e[34m'
  readonly NC=$'\e[0m'
  readonly STAGE_COLOR=$'\e[38;5;51m'
  readonly GRAY=$'\e[38;5;248m'
  readonly LOG_GRAY=$'\e[38;5;242m'
  readonly LIGHT_GRAY=$'\e[38;5;246m'
  readonly CLEANUP_COLOR=$'\e[38;5;219m'
}

function _init_logging()
{
  # Initialize phase 2
  # Only variables necessary for logging & start logging
  # Script related variables are defined in _init_script_variables
  readonly log_file="$dir"/logs/nuc-setup-$(date +"%d%m%y_%H%M").log
  {
    mkdir -p "$dir"/logs
  } ||
  {
    printf "${RED}✕ Failed to create logs folder${NC}\n"; exit 2
  }
  # tmp dir
  {
    rm -rf /tmp/ae/*
    mkdir -p /tmp/ae/
  } ||
  {
    printf "${RED}✕ Failed to create tmp folder${NC}\n"; exit 2
  }

  # if file not exists touch it
  if [[ ! -f ${log_file} ]]; then
    if touch "${log_file}"; then
      _log_info "Created log file"
    else
      printf "${RED}✕ Failed to create logfile!${NC}\n"
      exit 2
    fi
  fi

  # check if logs can be written
  if [[ -w $log_file ]]; then
    {
      _log_debug "Initialized logging"
    } ||
    {
      printf "${RED}✕ Failed to write to log file ${log_file} ${NC}\n"; exit 2
    }
  else
    printf "${RED}✕ Log file is not writable!${NC}\n"
    exit 2
  fi
}

function _line_fill()
{
  printf -- "-------------------------------------------------------\n"
}

function _log_and_exit()
{
  # ARG-1 log msg
  # ARG-2 exit code int
  local msg="$1"
  printf "${RED}  ✖ $msg ${NC}\n"
  printf "$(date) ${_crit} $msg\n" >> "$log_file"
  exit "$2"
}

function _script_exit_log()
{
    # Script time
    _log_stage "Cleanup and Exit"
    readonly AE_EXEC_END=$(date +%s)
    readonly AE_EXEC_TIME=$(( AE_EXEC_END - AE_EXEC_START ))
    _log_debug "$SCRIPT took $AE_EXEC_TIME seconds to complete."
    exit 0
}

function _log_info()
{
  local msg="$1"
  printf "  ➜ $msg\n"
  printf "$(date) ${_info} $msg\n" >> "$log_file"
}


function _log_debug()
{
  local msg="$1"
  if [[ ${AE_DEBUG} -gt 0 ]]; then
    printf "${GRAY}  » $msg${NC}\n"
  fi
  printf "$(date) ${_debug} $msg\n" >> "$log_file"
}


function _log_success()
{
  local msg="$1"
  printf "${GREEN}  ✔ $msg ${NC}\n"
  printf "$(date) ${_success} $msg\n" >> "$log_file"
}

function _log_warn()
{
  local msg="$1"
  printf "${YELLOW}  ⚠ $msg ${NC}\n"
  printf "$(date) ${_warn} $msg\n" >> "$log_file"
}


function _log_stage()
{
  local msg="$1"
  printf "${STAGE_COLOR}✈ $msg ${NC}\n"
  printf "$(date) ${_info} $msg\n" >> "$log_file"
}

function _log_cleanup()
{
  local msg="$1"
  printf "${CLEANUP_COLOR}  ♺ $msg ${NC}\n"
  printf "$(date) ${_cleanup} $msg\n" >> "$log_file"
}


function _log_error()
{
  local msg="$1"
  printf "${RED}  ✘ $msg ${NC}\n"
  printf "$(date) ${_error} $msg\n" >> "$log_file"
}


function _log_dev()
{
  local msg="$1"
  printf "${ORANGE}  ⚒ $msg ${NC}\n"
  printf "$(date) ${_dev} $msg\n" >> "$log_file"
}

function _log_inform()
{
  local msg="$1"
  printf "    ✦ $msg\n"
  printf "$(date) ${_info} $msg\n" >> "$log_file"
}

function _log_var()
{
  local var_name var_value
  var_name="$1"
  var_value="$2"
  if [[ $AE_DEBUG -gt 0 ]]; then
    printf "${GRAY}  ▿ %-20s - %-10s${NC}\n" "${var_name}" "${var_value}"
  fi
  printf "$(date) ${_variable} ${var_name} is set to ${var_value}\n" >> "$log_file"
}


function  _log_trace()
{
  # This function adds time stamp to logs without using external utilities
  # Output will be automatically written to $log_file
  # Arguments : 1
  # ARG -1: printf variable for formatting the log
  # Usage command | _add_timestamp_to_logs "$1"
  while IFS= read -r line;
  do
    printf "$(date) [EXT] ${1} %s\n" "$line" &>> "$log_file"
    if [[ $AE_DEBUG -gt 1 ]]; then
      printf "${LOG_GRAY}  #›%s %s${NC}\n" "$1" "$line"
    fi
  done

}