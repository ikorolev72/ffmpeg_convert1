#/bin/bash
# korolev-ia [] yandex.ru
# This script
# transcode video file into another format
# upload to external site
# 
# Arguments: id /path/filename.mp4 transcode_to_format
# eg transcoder.sh 123456789 /get_path/filename.mp4  640
BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1

# arguments
ID=$1
FILENAME=$2
TRANSCODE_FORMAT=$3

WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log

w2log "$@"

# check the arguments
if [[ "x$ID" == "x" || "x$FILENAME" == "x" || "x$TRANSCODE_FORMAT" == "x" ]] ; then
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


#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 320x180 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -level 30 -g 48 -b 200000 -threads 64 butterflyiphone_320.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 640x360 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -level 30 -g 48 -b 520000 -threads 64 butterflyiphone_640.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 320x180 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b 270000 -threads 64 butterfly_400.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 420x270 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b 570000 -threads 64 butterfly_700.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 720x406 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b 1000000 -threads 64 butterfly_1100.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 1024x576 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b 1200000 -threads 64 butterfly_1300.mp4
#ffmpeg -y -i Butterfly_HD_1080p.mp4 -s 1080x608 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b 1400000 -threads 64 butterfly_1500.mp4
#ffmpeg -i Butterfly_HD_1080p.mp4 -s 212x120 -y -strict experimental -acodec aac -ab 96k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -g 48 -b 85000 -level 30 -threads 64 butterfly_175k.mp4



OUTPUT_FILENAME=''
if [ "x${TRANSCODE_FORMAT}" == "x320" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 320x180 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -level 30 -g 48 -b:v 200000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x640" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 640x360 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -level 30 -g 48 -b:v 520000 -threads  4  ${OUTPUT_FILENAME}"
fi	

if [ "x${TRANSCODE_FORMAT}" == "x400" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 320x180 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b:v 270000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x700" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 420x270 -y -strict experimental -acodec aac -ab 64k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b:v 570000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x1100" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 720x406 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b:v 1000000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x1300" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 1024x576 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b:v 1200000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x1500" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 1080x608 -y -strict experimental -acodec aac -ab 128k -ac 2 -ar 48000 -vcodec libx264 -vprofile main -g 48 -b:v 1400000 -threads 4  ${OUTPUT_FILENAME}"
fi

if [ "x${TRANSCODE_FORMAT}" == "x175k" ] ; then
	OUTPUT_FILENAME=`${DIRNAME}/get_filename.pl $FILENAME ${TRANSCODE_FORMAT}`
	if [  $? -ne 0  ]; then
		w2log "Error: Incorrect filename '$FILENAME'. Cannot get extention for this file."
		rm -rf $MY_PID_FILE
		exit 1
	fi	
	CMD="timeout ${TIMEOUT_TRANSCODE} ${FFMPEG_DIR}/ffmpeg  -loglevel warning  -y  -i ${FILENAME} -s 212x120 -y -strict experimental -acodec aac -ab 96k -ac 2 -ar 48000 -vcodec libx264 -vprofile baseline -g 48 -b:v 85000 -level 30 -threads 4  ${OUTPUT_FILENAME}"
fi
# End of 'define transcoding command'


if [ "x${OUTPUT_FILENAME}" == "x" ]; then
	w2log "Error: Empty output filename, that mean unknown transcode format '$TRANSCODE_FORMAT'. Exiting"
	rm -rf $FILENAME
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
	rm -rf $FILENAME 
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

if [ "x$DEBUG" == "x1" ]; then
	echo ${DIRNAME}/send2queue.pl uploader "${DIRNAME}/uploader.sh $ID ${OUTPUT_FILENAME}"
else
	w2log "Put job in queue uploader: ${DIRNAME}/uploader.sh $ID ${OUTPUT_FILENAME}"
	${DIRNAME}/send2queue.pl uploader "${DIRNAME}/uploader.sh $ID ${OUTPUT_FILENAME}" >> ${PROCESS_LOG} 2>&1
fi

if [  $? -ne 0  ]; then
	w2log "Error: Cannot put job in queue. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
fi	


#w2log "Process $$ finished successfully"
rm -rf $MY_PID_FILE
exit 0