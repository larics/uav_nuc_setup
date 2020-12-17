function _init_print_basic_info()
{
  # This function logs and displays the Necessary details which helps in debugging.
  # Should be used after _init_script_variables function.
  _log_inform "Hostname      : ${CLIENT_NAME}"
  _log_inform "OS            : ${AE_DISTRO_PRETTY_NAME}"
  _log_inform "Distro        : ${AE_DISTRO_NAME}"
  _log_inform "Code Name     : ${AE_DISTRO_CODENAME}"
  _log_inform "Arch          : ${ARCH}"
  _log_inform "Version/Number: ${REL_NAME}/${REL_NUM}"

  _log_debug  "Path for sources.list.d: ${SOURCES_FILE_DIR}"

  #disable hist chars  so that I can print "!!"" properly
  histchars=
}

#shellcheck disable=SC2120
function detect_distribution()
{
  # Read /etc/os-release and get
  local OS_RELEASE_FILE

  OS_RELEASE_FILE="${1:-/etc/os-release}"
  if [[ -r "${OS_RELEASE_FILE}" ]]; then
    _log_debug "Found os-release file ${OS_RELEASE_FILE}"
    # Read Version Code Name
    readonly AE_DISTRO_CODENAME="$(awk '/VERSION_CODENAME=/' "${OS_RELEASE_FILE}" | sed 's/VERSION_CODENAME=//' | tr '[:upper:]' '[:lower:]')"

    # Read Human Readable Full Version Name
    readonly AE_DISTRO_PRETTY_NAME="$(awk '/PRETTY_NAME=/' "${OS_RELEASE_FILE}" | sed 's/PRETTY_NAME=//' | tr -d '"')"

    # Read Human Readable Distro Name
    readonly AE_DISTRO_NAME="$(awk '/^NAME=/' "${OS_RELEASE_FILE}" | sed 's/^NAME=//' | tr -d '"')"
  else
    _log_error "Hey, What kind of system is this?"
    _log_and_exit "I cannot determine distro/codename!" "5"
  fi
}


function _init_script_variables()
{
  # Function defines Script variables
  # Necessary variables used by the script are initialized here. This function
  # should be called first before choices are made, always.

  #shellcheck disable=SC2119
  detect_distribution

  # Achtung: Do not set code_name as readonly!!
  code_name="${AE_DISTRO_CODENAME}"
  readonly architecture="$(dpkg --print-architecture)"
  case "${architecture}" in
    amd64)          _log_debug "Architecture is 64 bit.";
                    readonly ARCH="amd64";
                    readonly YQ_BIN_ARCH="amd64";
                    ;;
    i386)           _log_debug "Architecture is 32 bit.";
                    _log_and_exit "i386 is no longer Supported!" "11"
                    ;;
    armhf)          _log_debug "Running on ARM CPU with HW Floating point Processor";
                    readonly ARCH="armhf";
                    readonly YQ_BIN_ARCH="arm";
                    ;;
    arm64)           _log_debug "This is an ARM 64. Please be advised that not all repositories support this arch.";
                    readonly ARCH="arm64";
                    readonly YQ_BIN_ARCH="arm";
                    ;;
    * )             _log_error "Sorry! This architecture is not supported by this script!"
                    _log_and_exit "Unsupported Architecture. $(architecture)" "11"
                    ;;
  esac
}

function cleanup {
  _log_cleanup "Resetting GitHub credentials."
  git config --global credential.helper 'cache --timeout 900'
  echo "protocol=https
host=github.com

" | git credential reject
}