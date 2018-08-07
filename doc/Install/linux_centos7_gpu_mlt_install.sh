#!/bin/bash
#****************************************************************#
# Author: yisheng.xp@alibaba-inc.com
# 该脚本主要用于在 centos7 操作系统(Linux e011239166174.et15sqa 3.10.0)下
# 自动安装 MLT 及其所需依赖，包括(yasm, ffmpeg, jack-audio, movit, qt, webvfx 等)
# 条件: 需要系统具备 yum 软件包管理器
#      需要curl 版本 >= 7.19.4
#      需要Git 版本 >=2.0
#***************************************************************#

######################################################################
# These are all of the configuration variables with defaults, you can change these.
INSTALL_DIR="$HOME/melt"
SOURCE_DIR="$INSTALL_DIR/src"
AUTO_APPEND_DATE=1
# Figure out the install dir - we may not install, but then we know it.
FINAL_INSTALL_DIR=$INSTALL_DIR
if test 1 = "$AUTO_APPEND_DATE" ; then
  FINAL_INSTALL_DIR="$INSTALL_DIR/`date +'%Y%m%d'`"
fi
######################################################################

######################################################################
# LOG FUNCTIONS
######################################################################
#################################################################
# log
# Function that prints a log line
# $@ : arguments to be printed
function log {
    echo "LOG: $@"
}
#################################################################
# die
# Function that prints a line and exists
# $@ : arguments to be printed
function die {
  echo "ERROR: $@"
  exit -1
}
#################################################################
# cmd
# Function that does a (non-background, non-outputting) command, after logging it
function cmd {
  log About to run command: "$@"
  "$@"
}
#################################################################
# init_log_file
# Write some init stuff
function init_log_file {
    log `date`
    log $0 starting
}

######################################################################
# Check Environment FUNCTIONS
######################################################################
#################################################################
# check_or_upgrade
# Check command version, and upgrade if current version is less than target version.
# $1: command  $2: target version  $3: version index
function check_or_upgrade {
    if command -v $1 >/dev/null 2>&1; then
        log "$1 has been installed, start to check version."
        command_version=$($1 --version 2>&1 | awk -v ver_index="$3" 'NR==1{print $ver_index}')
        log "$1 version is $command_version"
        if [[ $command_version < $2 ]]; then
          log "$1 version is less than $2, start to upgrade."
          cmd yum -y upgrade $1 || die "Unable to upgrade $1"
        fi
    else
        log "git has not been installed, start to install."
        cmd yum -y install $1 || die "Unable to install $1"
    fi
}
#################################################################
# check_env
# check base env before install mlt
function check_env {
    # check if yum has been installed
    command -v yum >/dev/null 2>&1 || die "Install mlt require yum, but it's not installed. Aborting."
    # check if curl has been installed and version > 7.19.4
    check_or_upgrade curl 7.19.4 2
    # check if git has been installed and vesion > 2.0
    check_or_upgrade git 2.0 3
    # Create install dir and src dir
    cmd mkdir -p $FINAL_INSTALL_DIR || die "Could not create install directory."
    cmd mkdir -p $SOURCE_DIR || die "Could not create src directory."
    # set global settings for all jobs
    export PATH="$FINAL_INSTALL_DIR/bin:$PATH"
    export LD_RUN_PATH="$FINAL_INSTALL_DIR/lib"
    export LD_LIBRARY_PATH="/lib:/lib64:/usr/lib:/usr/lib64::$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="$FINAL_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="/home/tops/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
    export PKG_CONFIG_PATH="$FINAL_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
    export PKG_CONFIG_PATH="$FINAL_INSTALL_DIR/share/pkgconfig:$PKG_CONFIG_PATH"
    export MANPATH=$MANPATH:"$FINAL_INSTALL_DIR/share/man"
    export CFLAGS="-I/usr/include -I$FINAL_INSTALL_DIR/include $CFLAGS"
    export CFLAGS="-I/usr/include/nvidia $CFLAGS"
    export CFLAGS="-I/usr/local/cuda-9.0/include/ $CFLAGS"
    export LDFLAGS="-L/usr/lib -L/usr/lib64 -L$FINAL_INSTALL_DIR/lib $LDFLAGS"
    export LDFLAGS="-L/usr/local/cuda-9.0/lib64/ $LDFLAGS"
}

######################################################################
# Install MLT and Library Dependencies FUNCTIONS
######################################################################

#################################################################
# base_library # 1. compile_install_yasm
function compile_install_yasm {
    cd $SOURCE_DIR
    curl -O http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar -xzvf yasm-1.3.0.tar.gz
    mkdir -p yasm-1.3.0/temp_build
    cd yasm-1.3.0/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib
    make
    make install
}
#################################################################
# base_library # 2. compile_install_eigen3
function compile_install_eigen3 {
    cd $SOURCE_DIR
    git clone http://github.com/RLovelett/eigen.git
    cd eigen
    git checkout branches/3.3
    mkdir temp_build
    cd temp_build
    cmake -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR ../
    make install
}

#################################################################
# ffmpeg # 1. compile_install_lame
function compile_install_lame_git {
    cd $SOURCE_DIR
    git clone http://github.com/rbrito/lame.git
    mkdir -p lame/temp_build
    cd lame/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib --enable-nasm
    make
    make install
}
#################################################################
# ffmpeg # 1. compile_install_lame_tgz
function compile_install_lame_tgz {
    cd $SOURCE_DIR
    curl -O http://nchc.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
    tar -xzvf lame-3.100.tar.gz
    mkdir -p lame-3.100/temp_build
    cd lame-3.100/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib --enable-nasm
    make
    make install
}
#################################################################
# ffmpeg # 2. compile_install_libvpx
function compile_install_libvpx {
    cd $SOURCE_DIR
    git clone http://github.com/webmproject/libvpx.git
    mkdir -p libvpx/temp_build
    cd libvpx/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --enable-vp8 --enable-vp9 --enable-postproc \
        --enable-multithread --enable-runtime-cpu-detect --disable-install-docs --disable-debug-libs \
        --disable-examples --disable-unit-tests --enable-shared
    make
    make install
}
#################################################################
# ffmpeg # 3. compile_install_x264
function compile_install_x264 {
    cd $SOURCE_DIR
    git clone http://repo.or.cz/x264.git
    mkdir -p x264/temp_build
    cd x264/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --disable-lavf --disable-ffms --disable-gpac --disable-asm --enable-shared
    make
    make install
}
#################################################################
# ffmpeg # 4. compile_install_x265
function compile_install_x265 {
    cd $SOURCE_DIR
    git clone http://github.com/videolan/x265.git
    mkdir -p x265/temp_build
    cd x265/temp_build
    cmake -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR ../source
    make install
}
#################################################################
# ffmpeg # 5. compile_install_vidstab
function compile_install_vidstab {
    cd $SOURCE_DIR
    git clone http://github.com/georgmartius/vid.stab.git
    mkdir -p vid.stab/temp_build
    cd vid.stab/temp_build
    cmake -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR ../
    make install
}
#################################################################
# ffmpeg # 6. compile_install_libwebp
function compile_install_libwebp {
    cd $SOURCE_DIR
    git clone http://github.com/webmproject/libwebp
    mkdir -p libwebp/temp_build
    cd libwebp
    ./autogen.sh
    cd temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --enable-libwebpdecoder
    make
    make install
}
#################################################################
# ffmpeg # 7 compile_install_ffmpeg
function compile_install_ffmpeg {
    cd $SOURCE_DIR
    git clone http://git.ffmpeg.org/ffmpeg.git
    cd ffmpeg
    git checkout release/3.3
    mkdir temp_build
    cd temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR --enable-gpl --enable-version3 --enable-shared \
        --enable-debug --enable-pthreads --enable-runtime-cpudetect --disable-doc \
        --enable-libmp3lame --enable-libpulse --enable-libtheora --enable-libvorbis \
        --enable-libvidstab --enable-libvpx --enable-libwebp --enable-libx264 \
        --enable-libx265 --enable-opengl --enable-nvenc --enable-nonfree
    make -j4
    make install
}

#################################################################
# movit # 1. compile_install_sdl2
function compile_install_sdl2 {
    cd $SOURCE_DIR
    curl -O http://www.libsdl.org/release/SDL2-2.0.7.tar.gz
    tar -xzvf SDL2-2.0.7.tar.gz
    mkdir -p SDL2-2.0.7/temp_build
    cd SDL2-2.0.7/temp_build
    ../configure --prefix=$FINAL_INSTALL_DIR
    make -j4
    make install
}
#################################################################
# movit # 2. compile_install_movit
function compile_install_movit {
    export CXXFLAGS="-std=c++11 $CFLAGS"
    cd $SOURCE_DIR
    git clone http://git.sesse.net/movit/
    cd movit
    git checkout -b 1.5.3 1.5.3
    sh autogen.sh --prefix=$FINAL_INSTALL_DIR
    make -j4
    make install
}

#################################################################
# qtwebkit # 1. compile_install_qt
function compile_install_qt {
    cd $SOURCE_DIR

    wget http://download.qt.io/official_releases/qt/5.9/5.9.1/single/qt-everywhere-opensource-src-5.9.1.tar.xz
    tar -xvJf  qt-everywhere-opensource-src-5.9.1.tar.xz
    mv qt-everywhere-opensource-src-5.9.1 qt-src-5.9.1
    cd qt-src-5.9.1
    ./configure -prefix $FINAL_INSTALL_DIR/Qt-5.9.1 -opensource -release -qt-xcb \
        -nomake tests -nomake examples -confirm-license -opengl
    gmake -j 4
    gmake install
    export PATH="$FINAL_INSTALL_DIR/Qt-5.9.1/bin:$PATH"
    export LD_LIBRARY_PATH="$FINAL_INSTALL_DIR/Qt-5.9.1/lib:$LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="$FINAL_INSTALL_DIR/Qt-5.9.1/lib/pkgconfig:$PKG_CONFIG_PATH"
}
#################################################################
# qtwebkit # 2. compile_install_qtwebkit
function compile_install_qtwebkit {
    cd $SOURCE_DIR
    cd qt-src-5.9.1
    git clone http://code.qt.io/qt/qtwebkit.git
    cd qtwebkit
    git checkout -b 5.9.0 origin/5.9.0
    $FINAL_INSTALL_DIR/Qt-5.9.1/bin/qmake
    make -j 4
    make install
}

#################################################################
# mlt # 1. compile_install_frei0r
function compile_install_frei0r {
    cd $SOURCE_DIR
    git clone http://github.com/dyne/frei0r.git
    cd frei0r
    ./autogen.sh
    ./configure --prefix=$FINAL_INSTALL_DIR
    make -j4
    make install
    export LD_LIBRARY_PATH="$FINAL_INSTALL_DIR/lib/frei0r-1:$LD_LIBRARY_PATH"
}
#################################################################
# mlt # 2. compile_install_mlt
function compile_install_mlt {
    cd $SOURCE_DIR
    git clone http://github.com/mltframework/mlt.git
    cd mlt
    git checkout -b 6.4.1 v6.4.1
    ./configure --prefix=$FINAL_INSTALL_DIR --enable-opengl --enable-gpl --enable-gpl3 \
        --enable-linsys --qt-libdir=$FINAL_INSTALL_DIR/Qt-5.9.1/lib \
        --qt-includedir=$FINAL_INSTALL_DIR/Qt-5.9.1/include
    make -j4
    make install
}

#################################################################
# webvfx # 1. compile_install_webvfx
function compile_install_webvfx {
    cd $SOURCE_DIR
    git clone http://github.com/mltframework/webvfx.git
    cd webvfx
    $FINAL_INSTALL_DIR/Qt-5.9.1/bin/qmake -r PREFIX=$FINAL_INSTALL_DIR MLT_SOURCE=$SOURCE_DIR/mlt
    make -j4
    make install
}
#################################################################
# webvfx # 2. compile_install_xvfb
function compile_install_xvfb {
    yum -y install xorg-x11-server-Xvfb
    export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    export DISPLAY=:0
    # nohup Xvfb :0 -screen 0 1600x1200x24 -dpi 240 >/dev/null 2>&1 &
}

#################################################################
# A # yum_install_base_library
function yum_install_base_library {
    cmd yum -y install yasm gavl-devel libsamplerate-devel libxml2-devel \
        ladspa-devel jack-audio-connection-kit-devel sox-devel SDL-devel \
        gtk2-devel libexif-devel libtheora-devel libvorbis-devel libvdpau-devel \
        libsoup-devel liboil-devel python-devel alsa-lib cmake kdelibs-devel \
        qimageblitz-devel qjson-devel xorg-x11-util-macros pulseaudio \
        pulseaudio-libs-devel libepoxy-devel
}
#################################################################
# B # compile_install_base_library
# install yasm and eigen3
function compile_install_base_library {
    compile_install_yasm
    compile_install_eigen3
}
#################################################################
# C # compile_install_ffmpeg and dependencies
function compile_install_ffmpeg_and_deps {
    compile_install_lame_tgz
    compile_install_libvpx
    compile_install_x264
    compile_install_x265
    compile_install_vidstab
    compile_install_libwebp
    compile_install_ffmpeg
}
#################################################################
# D # compile_install_movit and dependencies
function compile_install_movit_and_deps {
    cmd yum -y install fftw-devel gtest gtest-devel mesa-libEGL-devel mesa-libGLES-devel
    compile_install_sdl2
    compile_install_movit
}
#################################################################
# E # compile_install_qtwebkit and dependencies
function compile_install_qtwebkit_and_deps {
    cmd yum -y install alsa-lib libxcb-devel xcb-util-devel libjpeg-turbo-devel \
        libjpeg-turbo-utils mesa-dri-drivers
    cmd yum -y install gperf bison flex sqlite-devel fontconfig-devel phonon-devel \
        perl-core libpng-devel ruby libicu-devel libxslt-devel
    compile_install_qt
    compile_install_qtwebkit
}
#################################################################
# F # compile_install_mlt and dependencies
function compile_install_mlt_and_deps {
    compile_install_frei0r
    compile_install_mlt
}
#################################################################
# G # compile_install_webvfx and dependencies
function compile_install_webvfx_and_deps {
    compile_install_webvfx
    compile_install_xvfb
}


######################################################################
# Main
######################################################################
# Collects all the steps
function main {
    init_log_file
    check_env
    yum_install_base_library
    compile_install_base_library
    compile_install_ffmpeg_and_deps
    compile_install_movit_and_deps
    compile_install_qtwebkit_and_deps
    compile_install_mlt_and_deps
    compile_install_webvfx_and_deps
}

#################################################################

# Call main
main