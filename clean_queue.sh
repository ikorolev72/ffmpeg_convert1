#!/bin/bash
# korolev-ia [] yandex.ru
# This script clear all queue and remove all data
# 
# Arguments: id  transcode_to_format
# eg clean_queue.sh -f 
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
. "$DIRNAME/common.sh"

# check the arguments
if [[ "x$1" != "x-f" ]] ; then
	echo "Usage:$0 -f"
	exit 1
fi	

rm -rf $DATA_DIR/queue/*
# kill all transcoding processes
pkill -9 ffmpeg 
pkill -9 downloader.sh
pkill -9 uploader.sh
pkill -9 transcoder.sh

rm -rf $DATA_DIR/*


