#!/bin/bash
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
. "$DIRNAME/common.sh"

#DEBUG=1

ID=$1
WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log
 

w2log "$@"

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
.  $JOB_SETTINGS_FILE


DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/$$.downloader.pid"
echo  "$$"  > $MY_PID_FILE

cd $WORKING_DIR

[ -d "${WORKING_DIR}/${RELATIVE_DIR}" ] || mkdir -p "${WORKING_DIR}/${RELATIVE_DIR}"

for i in `seq 4`; do
	if [ "x$DEBUG" == "x1" ]; then
		echo timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE_FILE}" ${DOWNLOAD_TO}
	else
		w2log "Start download '${REMOTE_SOURCE_FILE}' and save to '${DOWNLOAD_TO}'. Attempt $i"
		timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE_FILE}" ${DOWNLOAD_TO} >> $PROCESS_LOG 2>&1
	fi

	if [  $? -eq 0  ]; then
		break
	fi
	# if unsuccess, try again 4 time
	w2log "Error: Cannot get file '${REMOTE_SOURCE_FILE}'. See $PROCESS_LOG"
	let SLEEP_TIME=" 120 * $i " 
	sleep $SLEEP_TIME	
done


if [ ! -f "${DOWNLOAD_TO}"  ]; then
	w2log "File ${DOWNLOAD_TO} do not exist"
	rm -rf $MY_PID_FILE
	exit 1
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