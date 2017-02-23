#!/bin/bash
# korolev-ia [] yandex.ru
# This script
# upload  video file  to external site
# 
# Arguments: id /path/filename.mp4 
# eg decoder.sh 123456789 relative_path/filename.mp4 
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
. "$DIRNAME/common.sh"

#DEBUG=1

# arguments
ID=$1
OUTPUT_FILENAME=$2

WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log


w2log "$@"

# check the arguments
if [[ "x$ID" == "x" || "x$OUTPUT_FILENAME" == "x"   ]] ; then
	echo "Usage:$0 id  /path/file.mp4 "
	exit 1
fi	

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/$$.uploader.pid"
echo  "$$"  > $MY_PID_FILE


cd $WORKING_DIR
if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f $OUTPUT_FILENAME  ]; then
		w2log "File $OUTPUT_FILENAME do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	

JOB_SETTINGS_FILE=${WORKING_DIR}/job_settings.sh
if [ ! -f $JOB_SETTINGS_FILE ]; then
	w2log "File $JOB_SETTINGS_FILE do not exist. Cannot set parameters"
	exit 1
fi
.  $JOB_SETTINGS_FILE


###################### put file to remote server


for i in `seq 4`; do
	CMD="timeout ${TIMEOUT_PUT_FILE} $RSYNC -aR ${OUTPUT_FILENAME} ${REMOTE_TARGET}"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD
	else
		w2log "Start upload '$OUTPUT_FILENAME' to '$REMOTE_TARGET' . Attempt $i"
		$CMD >> $PROCESS_LOG 2>&1
	fi

	if [  $? -eq 0  ]; then
		w2log "File '$OUTPUT_FILENAME'  uploaded to '$REMOTE_TARGET'"
		rm -rf $OUTPUT_FILENAME
		rm -rf $MY_PID_FILE
		exit 0
	fi
	# if unsuccess, try again 4 time
	let SLEEP_TIME=" 120 * $i " 
	sleep $SLEEP_TIME
done

w2log "Error: Cannot upload '$OUTPUT_FILENAME' to '$REMOTE_TARGET'. See $PROCESS_LOG"
rm -rf $MY_PID_FILE
exit 1
