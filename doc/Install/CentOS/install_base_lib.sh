#!/bin/sh
#****************************************************************#
# ScriptName: install_base_lib.sh
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
# Install_nvidia_driver in docker.
# This is deprecated
######################################################################
function try_to_install_nvidia_driver {
    if command -v nvidia-smi >/dev/null 2>&1; then
        log "nvidia driver has been installed. The GPU driver info as blow."
        cmd nvidia-smi
        read -p "Press any key to continue:" answer
    else
        log "nvidia driver has not been installed."
        read -p "Continue to install nvidia driver(y/Y), or refused(n/N):" answer
        if [ "$answer" = "y" -o "$answer" = "Y" ]; then
            log "Start to install nvidia driver."
            cmd yum -y install cuda-repo-rhel7-9-0-local -b current
            cmd yum -y install cuda
        elif [ "$answer" = "n" -o "$answer" = "N" ]; then
            log "Refused to install nvidia driver."
        else
            log "Can't recognize your input $answer, exit."
            exit 1
        fi
    fi
}
######################################################################
# Check if machine has GPU
# This is deprecated
######################################################################
function check_nvidia_driver {
    if command -v nvidia-smi >/dev/null 2>&1; then
        log "nvidia driver has been installed. The GPU driver info as blow."
        cmd nvidia-smi
        read -p "Press any key to continue:" answer
    else
        log "nvidia driver has not been installed."
        read -p "Continue to install mesa(y/Y), or exit(n/N):" answer
        if [ "$answer" = "y" -o "$answer" = "Y" ]; then
            log "Start to install mesal for OpenGL."
            cmd yum -y install mesa-dri-drivers mesa-libEGL-devel
        elif [ "$answer" = "n" -o "$answer" = "N" ]; then
            log "Refused to install mesa for OpenGL."
        else
            log "Can't recognize your input $answer, exit."
            exit 1
        fi
    fi
}
######################################################################
# Install base libraries by yum
######################################################################
function install_base_libraries {
    cmd yum -y install yasm gavl-devel libsamplerate-devel libxml2-devel \
        ladspa-devel jack-audio-connection-kit-devel sox-devel SDL-devel \
    	gtk2-devel libexif-devel libtheora-devel libvorbis-devel libvdpau-devel \
    	libsoup-devel liboil-devel python-devel alsa-lib cmake kdelibs-devel \
    	qimageblitz-devel qjson-devel xorg-x11-util-macros pulseaudio \
    	pulseaudio-libs-devel libepoxy-devel

    cmd yum -y install fftw-devel gtest gtest-devel mesa-libEGL-devel mesa-libGLES-devel

    cmd yum -y install alsa-lib libxcb-devel xcb-util-devel libjpeg-turbo-devel \
        libjpeg-turbo-utils mesa-dri-drivers

    cmd yum -y install gperf bison flex sqlite-devel fontconfig-devel phonon-devel \
        perl-core libpng-devel ruby libicu-devel libxslt-devel
}
######################################################################
# Install xvfb server that can run on machines with no display hardware and no physical input devices
######################################################################
function compile_install_xvfb {
    cmd yum -y install xorg-x11-server-Xvfb
    export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    export DISPLAY=:0
    # nohup Xvfb :0 -screen 0 1600x1200x24 -dpi 240 >/dev/null 2>&1 &
}
######################################################################
# Change info 'prefix=/MLTRootPATH' in all xxx.pc file for pkg-config
# This is deprecated
######################################################################
function change_prefix_config {
    MLT_ROOT_PATH=$(cd `dirname $0`; pwd)
    OLD_PREFIX=$(cat $MLT_ROOT_PATH/lib/pkgconfig/mlt++.pc | grep ^prefix=*)
    OLD_PATH=${OLD_PREFIX#*=}
    log "Current root path is : $MLT_ROOT_PATH , and old path is : $OLD_PATH"
    if [ -n "$OLD_PATH" -a "$OLD_PATH" != "$MLT_ROOT_PATH" ]; then
        log "Change old path: $OLD_PATH to current root path : $MLT_ROOT_PATH"
        sudo sed -i "s/${OLD_PATH//\//\\/}/${MLT_ROOT_PATH//\//\\/}/g" `find $MLT_ROOT_PATH -name "*.pc"`
        sudo sed -i "s/${OLD_PATH//\//\\/}/${MLT_ROOT_PATH//\//\\/}/g" `find $MLT_ROOT_PATH -name "*.la"`
        sudo sed -i "s/${OLD_PATH//\//\\/}/${MLT_ROOT_PATH//\//\\/}/g" `find $MLT_ROOT_PATH -name "*.prl"`
        sudo sed -i "s/${OLD_PATH//\//\\/}/${MLT_ROOT_PATH//\//\\/}/g" `find $MLT_ROOT_PATH -name "*.pri"`
        sudo sed -i "s/${OLD_PATH//\//\\/}/${MLT_ROOT_PATH//\//\\/}/g" $MLT_ROOT_PATH/bin/sdl2-config
    fi
}
######################################################################
# Start to run
######################################################################
install_base_libraries
compile_install_xvfb
