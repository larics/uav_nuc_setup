# This function will isntall essential tools and programs.
function install_essentials {
  _log_info "Installing essential tools and programs."

  ( \
  sudo apt-get update |& _log_trace "(ESS)" && \
  sudo apt-get upgrade -y |& _log_trace "(ESS)" && \
  sudo apt-get install -y --no-install-recommends tzdata dialog apt-utils |& _log_trace "(ESS)" \
  )

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing essentials."
    _log_and_exit "Please see the log file for more details." "11"
  fi

  sudo apt-get update |& _log_trace "(ESS)"
  sudo apt-get install -y \
    git\
    wget\
    zip\
    curl\
    gnupg2\
    libterm-readline-gnu-perl\
    lsb-release\
    |& _log_trace "(ESS)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing essentials."
    _log_and_exit "Please see the log file for more details." "12"
  fi

  _log_success "Done"
}

# This function will install various useful tools and utilities.
function install_tools {
  _log_info "Installing various useful tools and utilities."
  
  # CLI utilities for better user experiance.
  _log_inform "CLI utilities"
  sudo apt-get install -y \
    silversearcher-ag\
    ranger caca-utils highlight atool w3m poppler-utils mediainfo\
    htop\
    tmux\
    tmuxinator\
    moreutils\
    |& _log_trace "(UTIL)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing CLI utilities."
    _log_and_exit "Please see the log file for more details." "31"
  fi

  # Network tools.
  _log_inform "Network tools"
  sudo apt-get install -y \
    net-tools\
    openssh-server\
    nmap\
    |& _log_trace "(UTIL)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing network utilities."
    _log_and_exit "Please see the log file for more details." "32"
  fi

  _log_success "Done"
}

# This function will install ROS.
function install_ros {
  _log_info "Installing ROS."

  # Determine Ubuntu verion and corresponding ROS distribution.
  distro=`lsb_release -r | awk '{ print $2 }'`
  [ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
  [ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

  _log_inform "ROS distro is: $ROS_DISTRO"


  # Add ROS repositories and install base version.
  _log_inform "Adding ROS repositories"
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'


  for server in ha.pool.sks-keyservers.net \
                hkp://p80.pool.sks-keyservers.net:80 \
                keyserver.ubuntu.com \
                hkp://keyserver.ubuntu.com:80 \
                pgp.mit.edu; do
      sudo apt-key adv --keyserver "$server" --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 |& _log_trace "(ROS)" && break || echo "    Trying new server..."
  done

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while adding ROS repositories."
    _log_and_exit "It looks like none of the servers is available." "41"
  fi

  _log_inform "Installing base ROS"
  sudo apt-get -qq update
  sudo apt-get install -y ros-$ROS_DISTRO-ros-base |& _log_trace "(ROS)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing ROS."
    _log_and_exit "Please see the log file for more details." "42"
  fi

  _log_inform "Installing dependencies for building packages"
  sudo apt-get install -y \
   python-rosdep \
   python-rosinstall \
   python-rosinstall-generator \
   python-wstool \
   build-essential \
   python-rosdep \
   |& _log_trace "(ROS)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing dependencies for ROS packages."
    _log_and_exit "Please see the log file for more details." "43"
  fi

  _log_inform "Initializing rosdep"
  exit_status=0
  if [[ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]]; then
    sudo rosdep init |& _log_trace "(ROS)"
    exit_status=$?
  fi
  rosdep update |& _log_trace "(ROS)"
  (( exit_status = exit_status || $? ))

  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while initializing rosdep."
    _log_and_exit "Please see the log file for more details." "44"
  fi

  # Most common ROS packages.
  _log_inform "Installing most common ROS packages"
  sudo apt-get -y install \
    ros-$ROS_DISTRO-angles\
    ros-$ROS_DISTRO-camera-info-manager\
    ros-$ROS_DISTRO-cmake-modules\
    ros-$ROS_DISTRO-compressed-image-transport\
    ros-$ROS_DISTRO-control-toolbox\
    ros-$ROS_DISTRO-diagnostic-updater\
    ros-$ROS_DISTRO-eigen-conversions\
    ros-$ROS_DISTRO-geographic-msgs\
    ros-$ROS_DISTRO-image-geometry\
    ros-$ROS_DISTRO-image-transport-plugins\
    ros-$ROS_DISTRO-image-transport\
    ros-$ROS_DISTRO-nav-msgs\
    ros-$ROS_DISTRO-octomap-msgs\
    ros-$ROS_DISTRO-octomap\
    ros-$ROS_DISTRO-rosbash\
    ros-$ROS_DISTRO-rosconsole-bridge\
    ros-$ROS_DISTRO-rosdoc-lite\
    ros-$ROS_DISTRO-roslint\
    ros-$ROS_DISTRO-rviz-visual-tools\
    ros-$ROS_DISTRO-smach-*\
    ros-$ROS_DISTRO-tf-conversions\
    ros-$ROS_DISTRO-tf2-eigen\
    ros-$ROS_DISTRO-tf2-geometry-msgs\
    ros-$ROS_DISTRO-tf2-sensor-msgs\
    ros-$ROS_DISTRO-theora-image-transport\
    ros-$ROS_DISTRO-visualization-msgs\
    ros-$ROS_DISTRO-xacro\
    |& _log_trace "(ROS)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing ROS packages."
    _log_and_exit "Please see the log file for more details." "44"
  fi

  if [ "$distro" = "18.04" ]; then
    sudo apt-get -y install \
      ros-melodic-flexbe-behavior-engine\
      ros-melodic-hector-gazebo-plugins\
      ros-melodic-joy\
      ros-melodic-multimaster-*\
      ros-melodic-sophus\
      python-catkin-tools\
      |& _log_trace "(ROS)"

  elif [ "$distro" = "20.04" ]; then
    sudo apt-get -y install \
      ros-noetic-catkin\
      python3-catkin-tools\
      |& _log_trace "(ROS)"

  fi

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing ROS packages."
    _log_and_exit "Please see the log file for more details." "45"
  fi

  # Source ROS files.
  num=`cat ~/.bashrc | grep "/opt/ros/${ROS_DISTRO}/setup.bash" | wc -l`
  if [ "$num" -lt "1" ]; then
    sed -i "\@# ROS WORKSPACES@a source /opt/ros/$ROS_DISTRO/setup.bash" ~/.bashrc |& _log_trace "(ROS)"
  fi

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while adding ROS to .bashrc."
    _log_error "Please see the log file for more details."
    _log_dev "Manually add ROS sourcing to .bashrc"
    return
  fi

  _log_success "Done"
}

# This function will install all of the custom ROS packages.
function install_packages {
  _log_info "Installing custom ROS packages."

  # Determine Ubuntu verion and corresponding ROS distribution.
  distro=`lsb_release -r | awk '{ print $2 }'`
  [ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
  [ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

  # Install catkin_simple.
  _log_inform "catkin_simple"
  if [[ ! -d "$WORKSPACE_PATH/src/catkin_simple" ]]; then
    ( \
    cd -- "$WORKSPACE_PATH/src" && \
    git clone https://github.com/catkin/catkin_simple |& _log_trace "(CTK)" \
    )

    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
      _log_error "Something went wrong while cloning catkin_simple."
      _log_and_exit "Please see the log file for more details." "61"
      return
    fi
  fi

  # Install Velodyne drivers.
  _log_inform "velodyne"
  if [[ ! -d "$WORKSPACE_PATH/src/velodyne" ]]; then
    if [[ "$ROS_DISTRO" = "melodic" ]]; then
      ( \
      cd -- "$WORKSPACE_PATH/src" && \
      git clone https://github.com/ros-drivers/velodyne --branch melodic-devel --single-branch |& _log_trace "(CTK)"  && \
      rosdep install --from-paths velodyne --rosdistro $ROS_DISTRO -y |& _log_trace "(CTK)" \
      )

      exit_status=$?
      if [[ $exit_status -ne 0 ]]; then
        _log_error "Something went wrong while intalling velodyne drivers."
        _log_and_exit "Please see the log file for more details." "62"
        return
      fi

    else
      _log_warn "Velodyne drivers are available only for ROS melodic. Skipping."
    fi
  fi

  # Install TOPP-RA.
  _log_inform "TOPP-RA"
  if [[ ! -d "$HOME/third_party_software/toppra" ]]; then 
    ( \
    cd && \
    mkdir third_party_software |& _log_trace "(CTK)" && \
    cd third_party_software && \
    git clone https://github.com/hungpham2511/toppra |& _log_trace "(CTK)" && \
    cd toppra && \
    git checkout 8df858b08175d4884b803bf6ab7f459205e54fa2 |& _log_trace "(CTK)" && \
    pip install -r requirements.txt --user |& _log_trace "(CTK)" && \
    python setup.py install --user |& _log_trace "(CTK)" \
    )

    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
      _log_error "Something went wrong while intalling TOPP-RA."
      _log_and_exit "Please see the log file for more details." "63"
      return
    fi
  fi

  # Install MAVROS
  _log_inform "MAVROS"
  if [[ ! -d "$WORKSPACE_PATH/src/mavros" ]]; then
    ( \
    cd -- "$WORKSPACE_PATH" && \
    wstool init src |& _log_trace "(CTK)"  && \
    rosinstall_generator --rosdistro $ROS_DISTRO mavlink | tee /tmp/mavros.rosinstall |& _log_trace "(CTK)"  && \
    rosinstall_generator --upstream mavros | tee -a /tmp/mavros.rosinstall |& _log_trace "(CTK)"  && \
    wstool merge -t src /tmp/mavros.rosinstall |& _log_trace "(CTK)"  && \
    wstool update -t src -j4 |& _log_trace "(CTK)"  && \
    rosdep install --from-paths src --ignore-src -y |& _log_trace "(CTK)"  && \
    sudo ./src/mavros/mavros/scripts/install_geographiclib_datasets.sh |& _log_trace "(CTK)" \
    )

    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
      _log_error "Something went wrong while intalling MAVROS."
      _log_and_exit "Please see the log file for more details." "64"
      return
    fi
  fi

  # Clone LARICS packages using gitman.
  _log_inform "LARICS packages"
  ( \
    cd -- "$WORKSPACE_PATH" && \
    cp $dir/config/gitman.yaml ./.gitman.yaml |& _log_trace "(CTK)" && \
    gitman update |& _log_trace "(CTK)" \
  )

  exit_status=$?
  if [[ $exit_status -ne 0 ]]; then
    _log_error "Something went wrong while updating packages with gitman."
    _log_and_exit "Please see the log file for more details." "65"
    return
  fi

  _log_info "Building packages.\n"
  _line_fill
  # Build everything
  cd -- "$WORKSPACE_PATH"
  catkin build
  exit_status=$?
  _line_fill
  
  if [[ $exit_status -ne 0 ]]; then
    _log_error "Build failed."
    _log_and_exit "Please see the log file for more details." "66"
  fi

  _log_success "Done"

}

# This function will install gitman.
function install_gitman {
  _log_info "Installing gitman."

  distro=`lsb_release -r | awk '{ print $2 }'`
  if [ "$distro" = "18.04" ]; then
    sudo apt-get -y install python-pip python3-pip python-setuptools python3-setuptools |& _log_trace "(GTM)"
  elif [ "$distro" = "20.04" ]; then
    sudo apt-get -y install python3-pip python3-setuptools |& _log_trace "(GTM)"
  fi

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing gitman."
    _log_and_exit "Please see the log file for more details."
  fi

  sudo -H pip3 install gitman |& _log_trace "(GTM)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing gitman."
    _log_and_exit "Please see the log file for more details."
  fi

  _log_success "Done"
}

# This function will install general tools and programs.
function install_general {
  _log_info "Installing general tools and programs."

  # Build and install tools
  _log_inform "Build and install tools"
  sudo apt-get install -y \
    cmake\
    build-essential\
    autotools-dev\
    automake\
    autoconf\
    protobuf-compiler\
    distcc\
    |& _log_trace "(GEN)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing build tools."
    _log_and_exit "Please see the log file for more details." "21"
  fi

  # Determine Ubuntu verion and corresponding ROS distribution.
  distro=`lsb_release -r | awk '{ print $2 }'`
  [ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
  [ "$distro" = "20.04" ] && ROS_DISTRO="noetic"


  # Python-related packages.
  _log_inform "Python-related packages"
  if [ "$distro" = "18.04" ]; then
    sudo apt-get -y install \
      python-setuptools\
      python3-setuptools\
      python-prettytable\
      python-argparse\
      git-core\
      python-empy\
      python-serial\
      python-bloom\
      python-pip\
      python3-pip\
      python-future\
      python3-future\
      python-crcmod\
      |& _log_trace "(GEN)"

  elif [ "$distro" = "20.04" ]; then
    sudo apt-get -y install \
      python3-setuptools\
      python3-prettytable\
      python3-empy\
      python3-serial\
      python3-bloom\
      python3-osrf-pycommon\
      python3-pip\
      python3-future\
      python3-crcmod\
      |& _log_trace "(GEN)"
      # python3-argparse\ # TODO find an alternative

  fi

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing python packages."
    _log_and_exit "Please see the log file for more details." "22"
  fi

  # Various libraries and other stuff.
  _log_inform "Libraries and other stuff"
  sudo apt-get install -y\
    bison\
    flex\
    gcc-arm-none-eabi\
    geographiclib-tools\
    libeigen3-dev\
    libevent-dev\
    libftdi-dev\
    libgeographic-dev\
    libncurses5-dev\
    libncurses5-dev\
    libnlopt-dev\
    libopencv-dev\
    libqcustomplot-dev\
    libsuitesparse-dev\
    libtool\
    libx264-dev\
    libzstd-dev\
    ocl-icd-dev\
    ocl-icd-libopencl1\
    ocl-icd-opencl-dev\
    opencl-headers\
    xutils-dev\
    zlib1g-dev\
    |& _log_trace "(GEN)"

  exit_status=$?
  if [[ ! $exit_status -eq 0 ]]; then
    _log_error "Something went wrong while installing libraries."
    _log_and_exit "Please see the log file for more details." "23"
  fi

  # the "gce-compute-image-packages" package often freezes the installation at some point
  # the installation freezes when it tries to manage some systemd services
  # this attempts to install the package and stop the problematic service during the process
  # (sleep 90 && (sudo systemctl stop google-instance-setup.service && echo "gce service stoped" || echo "gce service not stoped")) &
  # (sudo timeout 120s apt-get -y install gce-compute-image-packages) || echo "\e[1;31mInstallation of gce-compute-image-packages failed\e[0m"

  _log_success "Done"
}