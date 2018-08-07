#!/bin/sh
#****************************************************************#
# ScriptName: install_fonts.sh
# Author: yisheng.xp@alibaba-inc.com
# Create Date: 2017-12-10 16:26
# Modify Author: yisheng.xp@alibaba-inc.com
# Modify Date: 2018-01-17 20:21
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
# Start to run
######################################################################
cd /usr/share/fonts
cmd wget http://video-advertise.cn-hangzhou.oss-cdn.aliyun-inc.com/fonts/ext_fonts.zip
cmd unzip -q ext_fonts.zip
cmd rm -rf ext_fonts.zip
cmd fc-cache -fv ext_fonts
cmd fc-list :lang=zh