#/bin/bash
# korolev-ia [] yandex.ru
# This downloader download the file with rsync
# transcode into another format
# upload to new resource
# 
# Arguments: rsync://get_path/ filename.mp4 rsync://put_path/ [ transcode_to_format ]
# eg downloader.sh rsync://user@domain.com:/get_path/ filename.mp4 rsync://user@domain.com:/put_path/
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1

ID=$1
GET_PATH=$2
FILENAME=$3
PUT_PATH=$4
TRANSCODE_FORMAT=$4


WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log
TRANSCODE_FORMATS_LIST='h264' 
#export TRANSCODE_FORMATS_LIST='h264 z123' 


w2log "$@"

# check the arguments
if [[ "x$ID" == "x" || "x$GET_PATH" == "x" || "x$FILENAME" == "x" || "x$PUT_PATH" == "x"   ]] ; then
	echo "Usage:$0 id rsync://user@domain.com:/path/ file.mp4 rsync://user@domain.com:/path_for_transcoded_files/ [transcode_to_format]"
	exit 1
fi	


if [ "x$TRANSCODE_FORMAT" != "x" ] ; then
	TRANSCODE_FORMATS_LIST=$TRANSCODE_FORMAT
fi

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/$$.downloader.pid"
echo  "$$"  > $MY_PID_FILE


CMD="timeout $TIMEOUT_GET_FILE $RSYNC $GET_PATH/$FILENAME $WORKING_DIR"
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD
else
	w2log "Start download '$GET_PATH/$FILENAME' and save to '$WORKING_DIR'"
	$CMD >> $PROCESS_LOG 2>&1
fi

if [  $? -ne 0  ]; then
	w2log "Error: Cannot get file $GET_PATH/$FILENAME. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
fi	



if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f "$WORKING_DIR/$FILENAME"  ]; then
		w2log "File $WORKING_DIR/$FILENAME do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	

for i in $TRANSCODE_FORMATS_LIST; do
	SOURCE_FILENAME="$FILENAME_link_$i.mp4"
	CMD="ln $DOWNLOAD_DIR/$FILENAME $DOWNLOAD_DIR/$SOURCE_FILENAME"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Make hard link $DOWNLOAD_DIR/$FILENAME to $DOWNLOAD_DIR/$SOURCE_FILENAME"
		$CMD >> $PROCESS_LOG 2>&1
		if [  $? -ne 0  ]; then
			w2log "Error: Faied make hard link $DOWNLOAD_DIR/$FILENAME to $DOWNLOAD_DIR/$SOURCE_FILENAME"
			rm -rf $MY_PID_FILE
			exit 1			
		fi			
	fi
	CMD="$DIRNAME/send2queue.pl transcoder '$DIRNAME/transcoder.sh $ID $DOWNLOAD_DIR/$SOURCE_FILENAME $PUT_PATH $i'"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Put job in queue: transcoder '$DOWNLOAD_DIR/$SOURCE_FILENAME' to $i'"
		$CMD >> $PROCESS_LOG 2>&1
	fi
	if [  $? -ne 0  ]; then
		w2log "Error: Cannot get file $GET_PATH/$FILENAME. See $PROCESS_LOG"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
done

w2log "Job $$ finished successfully"
rm -rf $MY_PID_FILE
exit 0