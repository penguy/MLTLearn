#!/bin/sh
#****************************************************************#
# ScriptName: install_gpu_driver.sh
# Author: penguy@qq.com
# Create Date: 2017-12-10 16:26
# Modify Author: $SHTERM_REAL_USER
# Modify Date: 2018-01-17 20:53
# Function:
#***************************************************************#

######################################################################
# LOG FUNCTIONS
######################################################################
# Function that prints a log line
# $@ : arguments to be printed
function log {
    echo "LOG: $@"
}
# Function that does a (non-background, non-outputting) command, after logging it
# $@ : arguments to be execute
function cmd {
  log About to run command: "$@"
  "$@"
}

######################################################################
# Upgrade docker kernel and kernel-headers if kernel lib modules is different from host machine
######################################################################
function check_and_upgrade_kernel_modules {
    sys_uname_r=$(uname -r)
    log "Current docker system kernel version is : ${sys_uname_r}"
    if [[ -d "/lib/modules/${sys_uname_r}" ]]; then
        log "/lib/modules/${sys_uname_r} folder is exist."
    else
        log "/lib/modules/${sys_uname_r} folder is not exist. Start to upgrade kernel modules."
        cmd sudo yum -y install kernel-$(uname -r) kernel-devel-$(uname -r) kernel-headers-$(uname -r)
        cmd sudo yum -y install "kernel-devel-uname-r == $(uname -r)"
    fi
}
######################################################################
# Check if machine has GPU driver
######################################################################
function check_and_install_nvidia_driver {
    if command -v nvidia-smi >/dev/null 2>&1; then
        log "Nvidia gpu driver has been installed. The driver info as blow."
        cmd nvidia-smi
    else
        log "Nvidia gpu driver has not been installed."
        check_and_upgrade_kernel_modules
        log "Start to install nvidia driver..."
        cmd sudo yum -y install cuda-repo-rhel7-9-0-local --disablerepo=ops.7.x86_64 -b current
        cmd sudo yum -y install cuda --disablerepo=ops.7.x86_64
        log "Install nvidia driver successfully. The driver info as blow."
        cmd nvidia-smi
    fi
}
######################################################################
# Check if machine has gpu device in docker
######################################################################
function check_gpu_device {
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        log "Nvidia gpu device exists. The GPU device info as blow."
        cmd lspci | grep -i nvidia
        log "The GPU device version as blow."
        cmd cat /proc/driver/nvidia/version
        log "Start to check nvidia driver..."
        check_and_install_nvidia_driver
    else
        log "Nvidia gpu device is not exist. Skip."
    fi
}
######################################################################
# Start to run
######################################################################
check_gpu_device
