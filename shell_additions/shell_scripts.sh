#!/bin/bash
# ROS shell scripts
# Credit to https://github.com/ctu-mrs/mrs_uav_system

waitForRos() {
  until rostopic list > /dev/null 2>&1; do
    echo "waiting for ros"
    sleep 1;
  done
}

waitForSimulation() {
  until timeout 3s rostopic echo /gazebo/model_states -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for simulation"
    sleep 1;
  done
  sleep 1;
}

waitForOdometry() {
  until timeout 3s rostopic echo /$UAV_NAMESPACE/mavros/local_position/odom -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for odometry"
    sleep 1;
  done
}

waitForGlobal() {
  until timeout 3s rostopic echo /$UAV_NAMESPACE/mavros/global_position/local -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for global odometry"
    sleep 1;
  done
}

waitForCarrot() {
  until timeout 3s rostopic echo /$UAV_NAMESPACE/carrot/status -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for carrot"
    sleep 1;
  done
}

waitForMavros() {
  until timeout 3s rostopic echo /$UAV_NAMESPACE/mavros/state -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for mavros"
    sleep 1;
  done
}

# allows killing process with all its children
killp() {

  if [ $# -eq 0 ]; then
    echo "The command killp() needs an argument, but none was provided!"
    return
  else
    pes=$1
  fi

  for child in $(ps -o pid,ppid -ax | \
    awk "{ if ( \$2 == $pes ) { print \$1 }}")
    do
      # echo "Killing child process $child because ppid = $pes"
      killp $child
    done

# echo "killing $1"
kill -9 "$1" > /dev/null 2> /dev/null
}