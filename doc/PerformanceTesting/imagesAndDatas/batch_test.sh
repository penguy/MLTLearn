#!/bin/sh
#****************************************************************#
# ScriptName: batch_test.sh
# Author: yisheng.xp@alibaba-inc.com
# Create Date: 2018-03-05 16:26
# Modify Author: yisheng.xp@alibaba-inc.com
# Modify Date: 2018-03-06 10:21
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

######################################################################
# main shell
######################################################################
if [[ ! $1 ]]; then
    log "No input for test total number. Exit!"
    exit 1
fi
if [[ $1 -le 0 || $1 -ge 100 ]]; then
    log "Your input is $1, which is not valid(1 ~ 99). Exit!"
    exit 1
fi
log "Start to run batch test task for $1 times."

for (( i = 0; i < $1; i++ )); do
    if [[ "$2" == "gpu" ]]; then
        nohup time melt test.xml -consumer avformat vcodec=h264_nvenc target=single_task_gpu_"$i".mp4 > "logs/$i".log 2>&1 &
    else
        nohup time melt test.xml -consumer avformat:single_task_"$i".mp4 > "logs/$i".log 2>&1 &
    fi
done