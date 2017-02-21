#/bin/bash
# korolev-ia [] yandex.ru
# This job_starter
# check the new files, check the queue and run tasks
# 

BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1


WORKING_DIR=$DATA_DIR/job_starter
PROCESS_LOG=$WORKING_DIR/job_starter.log
VIDEO_EXT='\.mp4$|\.avi$|\.mkv$'

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/job_starter.pid" 
if [ -f  $MY_PID_FILE ]; then 
	ps --pid `cat $MY_PID_FILE` -o cmd h  >/dev/null 2>&1 
	if [ $? -eq 0 ]; then
		# previrouse job_starter don't finished yet
		exit 0
	fi				
fi
echo  $$  > $MY_PID_FILE


########## check failed jobs
# check downloader jobs
for pid_file in  `find $DATA_DIR -name '*.downloader.pid' -o -name '*.transcoder.pid'  -o -name '*.uploader.pid'`; do
	ps --pid `cat $pid_file` -o cmd h >/dev/null 2>&1 
	if [ $? -ne 0 ]; then
		# remove pid-files for failed job ( process crashed or killed )
		rm $pid_file
	fi		
done
# end of check


########## run jobs in the queues
# queue downloader
RUNNING_JOBS=`find $DATA_DIR -name "*.downloader.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_DOWNLOADER` ; do
	JOB=`$DIRNAME/getfromqueue.pl downloader`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done

# queue transcoder
RUNNING_JOBS=`find $DATA_DIR -name "*.transcoder.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_TRANSCODER` ; do
	JOB=`$DIRNAME/getfromqueue.pl transcoder`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done
# queue uploader
RUNNING_JOBS=`find $DATA_DIR -name "*.uploader.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_UPLOADER` ; do
	JOB=`$DIRNAME/getfromqueue.pl uploader`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done
# end of job starter


CMD="timeout $TIMEOUT_GET_LS $RSYNC --list-only $REMOTE_SOURCE" 
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD  "| /bin/egrep -i $VIDEO_EXT > $WORKING_DIR/ls.tmp"
else
	$CMD  | /bin/egrep -i $VIDEO_EXT > $WORKING_DIR/ls.tmp
fi

# now we check if file don't changes during a minute 
CMD="cp -pf $WORKING_DIR/ls.tmp $WORKING_DIR/ls.tmp.old"
if [ ! -f $WORKING_DIR/ls.tmp.old ]; then
	# first start
	$CMD
	rm $MY_PID_FILE
	exit 0
fi
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD
else
	$CMD
fi



IFS=$'\n'
for next in `$DIRNAME/same_strings.pl --f1=$WORKING_DIR/ls.tmp --f2=$WORKING_DIR/ls.tmp.old`
do
	ID=`echo $next | /usr/bin/md5sum | awk '{ print $1 }'`
	if [ -d $DATA_DIR/$ID ]; then
		continue
	fi
	FILENAME=`echo $next  | /usr/bin/perl -ne '/^\S+\s+\S+\s+\S+\s+\S+\s+(.+)$/; print unpack( "h*","$1" );'`
	# we use unpacked in hex format filename (for spaces and special chars)
	# for decode use perl -e 'print pack( "h*", "hex_string" )."\n";'
	#
	if [ "x$DEBUG" == "x1" ]; then
		echo ${DIRNAME}/send2queue.pl downloader "${DIRNAME}/downloader.sh $ID $REMOTE_SOURCE $FILENAME $REMOTE_TARGET"
		echo "mkdir $DATA_DIR/$ID"
	else
		w2log "Put job in queue downloader: ${DIRNAME}/downloader.sh $ID $REMOTE_SOURCE $FILENAME $REMOTE_TARGET"
		${DIRNAME}/send2queue.pl downloader "${DIRNAME}/downloader.sh $ID $REMOTE_SOURCE $FILENAME $REMOTE_TARGET" >> ${PROCESS_LOG} 2>&1
		
		if [ $? -ne 0 ]; then
			w2log "Error: Cannot put job in queue. See $PROCESS_LOG"
			continue
		fi		
		mkdir ${DATA_DIR}/${ID}
	fi			
done



#
rm -rf $MY_PID_FILE
exit 0