#/bin/bash
# korolev-ia [] yandex.ru
# This script
# upload  video file  to external site
# 
# Arguments: id /path/filename.mp4 
# eg decoder.sh 123456789 /get_path/filename.mp4 
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

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



if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f $OUTPUT_FILENAME  ]; then
		w2log "File $OUTPUT_FILENAME do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	


###################### put file to remote server
CMD="timeout ${TIMEOUT_PUT_FILE} $RSYNC ${OUTPUT_FILENAME} ${REMOTE_TARGET}"
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD
else
	w2log "Start upload '$OUTPUT_FILENAME' to '$REMOTE_TARGET'"
	$CMD >> $PROCESS_LOG 2>&1
fi

if [  $? -ne 0  ]; then
	w2log "Error: Cannot upload '$OUTPUT_FILENAME' to '$REMOTE_TARGET'. See $PROCESS_LOG"
	#rm -rf $OUTPUT_FILENAME
	rm -rf $MY_PID_FILE
	exit 1
fi	


#w2log "Process $$ finished successfully"
rm -rf $OUTPUT_FILENAME
rm -rf $MY_PID_FILE
exit 0