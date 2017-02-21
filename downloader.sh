#/bin/bash
# korolev-ia [] yandex.ru
# This downloader download the file with rsync
# transcode into another format
# upload to new resource
# 
# Arguments:  unpacked_in_hex_filename  [ transcode_to_format ]
# or
# Arguments:  filename [ transcode_to_format ]
# eg downloader.sh  abc.avi
# also possible 
# eg downloader.sh  012345abcdef 

BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1

ID=$1
HEX_FILENAME=$2
TRANSCODE_FORMAT=$3

WORKING_DIR=$DATA_DIR/$ID
PROCESS_LOG=$WORKING_DIR/$$.log
#TRANSCODE_FORMATS_LIST='320' 
TRANSCODE_FORMATS_LIST='320 640 400 700 1100 1300 1500 175k' 


# check the arguments
if [[ "x$ID" == "x" ||  "x$HEX_FILENAME" == "x"   ]] ; then
	echo "Usage:$0 id file.mp4  [transcode_to_format]"
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

# check if filename in simple text or "hex packed" ( check if found '.' in string)
echo $HEX_FILENAME | grep "\." >/dev/null 2>&1
if [  $? -ne 0  ]; then
	FILENAME=`echo $HEX_FILENAME | /usr/bin/perl -ne 'print pack( "h*",$_);'`
else
	FILENAME=$HEX_FILENAME
fi	

OUTPUT_FILENAME=`echo $FILENAME | /usr/bin/perl -ne '/^(.+)\.(\w+)$/; my $filename=$1; my $ext=$2; $filename=~s/\W/_/g; print "$filename.$ext";'`
# output filename with fixed special chars and spaces

if [ "x$DEBUG" == "x1" ]; then
	echo timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE}/${FILENAME}" ${WORKING_DIR}/${OUTPUT_FILENAME}
else
	w2log "Start download '${REMOTE_SOURCE}/${FILENAME}' and save to '$WORKING_DIR/${OUTPUT_FILENAME}'"
	timeout ${TIMEOUT_GET_FILE} $RSYNC "${REMOTE_SOURCE}/${FILENAME}" ${WORKING_DIR}/${OUTPUT_FILENAME} >> $PROCESS_LOG 2>&1
fi

if [  $? -ne 0  ]; then
	w2log "Error: Cannot get file '${REMOTE_SOURCE}/${FILENAME}'. See $PROCESS_LOG"
	rm -rf $MY_PID_FILE
	exit 1
fi	



if [ "x$DEBUG" != "x1" ]; then
	if [ ! -f "$WORKING_DIR/${OUTPUT_FILENAME}"  ]; then
		w2log "File $WORKING_DIR/${OUTPUT_FILENAME} do not exist"
		rm -rf $MY_PID_FILE
		exit 1
	fi	
fi	


for i in $TRANSCODE_FORMATS_LIST; do
	SOURCE_FILENAME="${OUTPUT_FILENAME}.${i}"
	CMD="ln ${WORKING_DIR}/${OUTPUT_FILENAME} ${WORKING_DIR}/${SOURCE_FILENAME}"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Make hard link ${WORKING_DIR}/${OUTPUT_FILENAME} to ${WORKING_DIR}/${SOURCE_FILENAME}"
		[ -f ${WORKING_DIR}/${SOURCE_FILENAME} ] || $CMD >> $PROCESS_LOG 2>&1
		if [  $? -ne 0  ]; then
			w2log "Error: Faied make hard link ${WORKING_DIR}/${OUTPUT_FILENAME} to ${WORKING_DIR}/${SOURCE_FILENAME}"
			continue
		fi			
	fi
	if [ "x$DEBUG" == "x1" ]; then
		echo ${DIRNAME}/send2queue.pl transcoder "${DIRNAME}/transcoder.sh $ID ${WORKING_DIR}/${SOURCE_FILENAME}  $i"
	else
		w2log "Put job in queue transcoder: ${DIRNAME}/transcoder.sh $ID ${WORKING_DIR}/${SOURCE_FILENAME}  $i"
		${DIRNAME}/send2queue.pl transcoder "${DIRNAME}/transcoder.sh $ID ${WORKING_DIR}/${SOURCE_FILENAME}  $i" >> ${PROCESS_LOG} 2>&1
	fi
	if [  $? -ne 0  ]; then
		w2log "Error: Cannot put job in queue. See $PROCESS_LOG"
		rm -rf ${WORKING_DIR}/${SOURCE_FILENAME}
		continue
	fi	
done

#w2log "Process $$ finished successfully"
rm -rf ${WORKING_DIR}/${OUTPUT_FILENAME}
rm -rf $MY_PID_FILE
exit 0