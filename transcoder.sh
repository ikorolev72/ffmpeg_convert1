#/bin/bash
# korolev-ia [] yandex.ru
# This script
# transcode video file into another format
# upload to external site
# 
# Arguments: id /path/filename.mp4 rsync://put_path/ transcode_to_format
# eg decoder.sh 123456789 /get_path/ filename.mp4 rsync://user@domain.com:/put_path/ h264
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1

# arguments
ID=$1
FILENAME=$2
PUT_PATH=$3
TRANSCODE_FORMAT=$4

WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log

w2log "$@"

# check the arguments
if [[ "x$ID" == "x" || "x$FILENAME" == "x" || "x$PUT_PATH" == "x" || "x$TRANSCODE_FORMAT" == "x" ]] ; then
	echo "Usage:$0 id  file.mp4 rsync://user@domain.com:/path_for_transcoded_files/ transcode_to_format"
	exit 1
fi	

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/$$.transcoder.pid"
echo  "$$"  > $MY_PID_FILE



if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f "$FILENAME"  ]; then
		w2log "File $FILENAME do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	


OUTPUT_FILENAME=''
if [ "x$TRANSCODE_FORMAT" == "xh264" ] ; then
	OUTPUT_FILENAME="${FILENAME}_${TRANSCODE_FORMAT}.mp4" 
	# we need parse filename and change it
	CMD="timeout $TIMEOUT_TRANSCODE $FFMPEG_DIR/ffmpeg -i $FILENAME -vf 'scale:1920x1080' -c:v libx264 -pix_fmt yuv420p -strict -2 $OUTPUT_FILENAME"
fi	

if [ "x$OUTPUT_FILENAME" == "x" ]; then
	w2log "Error: Unknown transcode format '$TRANSCODE_FORMAT'. Exiting"
	rm -rf $MY_PID_FILE
	exit 1
fi

if [ "x$DEBUG" == "x1" ]; then
	echo $CMD 
else
	w2log "Start transcode '$FILENAME'"
	$CMD >> $PROCESS_LOG 2>&1
fi

if [  $? -ne 0 ]; then
	w2log "Error: Cannot transcode file '$FILENAME' to '$OUTPUT_FILENAME' with '$TRANSCODE_FORMAT'. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
else 
	CMD="rm -rf $FILENAME"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD
	else
		$CMD >> $PROCESS_LOG 2>&1
	fi
fi	

###################### put job in the queue for upload to remote server

CMD="$DIRNAME/send2queue.pl uploader '$DIRNAME/uploader.sh $ID $OUTPUT_FILENAME $PUT_PATH'"
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD 
else
	w2log "Put job in queue: uploader '$OUTPUT_FILENAME' to '$PUT_PATH'"
	$CMD >> $PROCESS_LOG 2>&1
fi
if [  $? -ne 0  ]; then
	w2log "Error: Cannot put job in the queue. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
fi	


w2log "Job $$ finished successfully"
rm -rf $MY_PID_FILE
exit 0