#!/bin/sh
#****************************************************************#
# ScriptName: set_env.sh
# Author: yisheng.xp@alibaba-inc.com
# Create Date: 2017-12-10 16:26
# Modify Author: yisheng.xp@alibaba-inc.com
# Modify Date: 2018-01-17 20:21
# Function: Set MLT run time environment
#***************************************************************#
INSTALL_DIR="/usr/meltdir/20180305"
export PATH="$INSTALL_DIR/bin:$PATH"
export LD_RUN_PATH="$INSTALL_DIR/lib"
export LD_LIBRARY_PATH="/lib:/lib64:/usr/lib:/usr/lib64::$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/Qt-5.9.1/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib/frei0r-1:$LD_LIBRARY_PATH"
export MANPATH=$MANPATH:"$INSTALL_DIR/share/man"
export PKG_CONFIG_PATH="/home/tops/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/Qt-5.9.1/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I/usr/include -I$INSTALL_DIR/include $CFLAGS"
export CXXFLAGS="-std=c++11 $CFLAGS"
export CFLAGS="-I/usr/include/nvidia $CFLAGS"
export CFLAGS="-I/usr/local/cuda-9.0/include/ $CFLAGS"
export LDFLAGS="-L/usr/lib -L/usr/lib64 -L$INSTALL_DIR/lib $LDFLAGS"
export LDFLAGS="-L/usr/local/cuda-9.0/lib64/ $LDFLAGS"
export QT_XKB_CONFIG_ROOT="/usr/share/X11/xkb"
export DISPLAY=:0
export MLT_REPOSITORY="$INSTALL_DIR/lib/mlt"
export MLT_DATA="$INSTALL_DIR/share/mlt"
export MLT_PROFILES_PATH="$INSTALL_DIR/share/mlt/profiles"
export MLT_MOVIT_PATH="$INSTALL_DIR/share/movit"
export FREI0R_PATH="$INSTALL_DIR/lib/frei0r-1"
export QT_PLUGIN_PATH="$INSTALL_DIR/Qt-5.9.1/plugins"
export QML2_IMPORT_PATH="$INSTALL_DIR/Qt-5.9.1/qml"