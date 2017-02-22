#/bin/bash
# korolev-ia [] yandex.ru
# This downloader download the file with rsync
# transcode into another format
# upload to new resource
# 
# Arguments:  id
# or
# Arguments:  id
# eg downloader.sh  123


BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1

ID=$1
WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log
TRANSCODE_FORMATS_LIST='320 640 400 700 1100 1300 1500 175k' 

# check the arguments
if [[ "x$ID" == "x"  ]] ; then
	echo "Usage:$0 id "
	exit 1
fi	

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

JOB_SETTINGS_FILE=${WORKING_DIR}/job_settings.sh
if [ ! -f $JOB_SETTINGS_FILE ]; then
	w2log "File $JOB_SETTINGS_FILE do not exist. Cannot set parameters"
	exit 1
fi
source $JOB_SETTINGS_FILE


DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/$$.downloader.pid"
echo  "$$"  > $MY_PID_FILE

# check if filename in simple text or "hex packed" ( check if found '.' in string)
#echo $HEX_FILENAME | grep "\." >/dev/null 2>&1
#if [  $? -ne 0  ]; then
#	FILENAME=`echo $HEX_FILENAME | /usr/bin/perl -ne 'print pack( "h*",$_);'`
#else
#	FILENAME=$HEX_FILENAME
#fi	

#OUTPUT_FILENAME=`echo $FILENAME | /usr/bin/perl -ne '/^(.+)\.(\w+)$/; my $filename=$1; my $ext=$2; $filename=~s/\W/_/g; print "$filename.$ext";'`
# output filename with fixed special chars and spaces

if [ "x$DEBUG" == "x1" ]; then
	echo timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE_FILE}" ${DOWNLOAD_TO}
else
	w2log "Start download '${RREMOTE_SOURCE_FILE}' and save to '${DOWNLOAD_TO}'"
	timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE_FILE}" ${DOWNLOAD_TO} >> $PROCESS_LOG 2>&1
fi

if [  $? -ne 0  ]; then
	w2log "Error: Cannot get file '${REMOTE_SOURCE_FILE}'. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
fi	



if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f "${DOWNLOAD_TO}"  ]; then
		w2log "File ${DOWNLOAD_TO} do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	


for i in $TRANSCODE_FORMATS_LIST; do
	CMD="ln ${DOWNLOAD_TO} ${DOWNLOAD_TO}.${i}"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Make hard link ${DOWNLOAD_TO} ${DOWNLOAD_TO}.${i}"
		[ -f "${DOWNLOAD_TO}.${i}" ] || $CMD >> $PROCESS_LOG 2>&1
		if [  $? -ne 0  ]; then
			w2log "Error: Faied make hard link ${DOWNLOAD_TO} to ${DOWNLOAD_TO}.${i}"
			continue
		fi			
	fi
	if [ "x$DEBUG" == "x1" ]; then
		echo ${DIRNAME}/send2queue.pl transcoder "${DIRNAME}/transcoder.sh $ID $i"
	else
		w2log "Put job in queue transcoder: ${DIRNAME}/transcoder.sh $ID $i"
		${DIRNAME}/send2queue.pl transcoder "${DIRNAME}/transcoder.sh $ID $i" >> ${PROCESS_LOG} 2>&1
	fi
	if [  $? -ne 0  ]; then
		w2log "Error: Cannot put job in queue. See $PROCESS_LOG"
		rm -rf "${DOWNLOAD_TO}.${i}"
		continue
	fi	
done

#w2log "Process $$ finished successfully"
rm -rf ${DOWNLOAD_TO}
rm -rf $MY_PID_FILE
exit 0