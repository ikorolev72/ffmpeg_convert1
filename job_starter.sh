#/bin/bash
# korolev-ia [] yandex.ru
# This watchdog
# check the new files, check the queue and run tasks
# 

BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
source "$DIRNAME/common.sh"

#DEBUG=1


WORKING_DIR=$DATA_DIR/watchdog
PROCESS_LOG=$WORKING_DIR/watchdog.log
VIDEO_EXT="'.mp4$|.avi$|.mkv$'"

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	

DATE=`date +%Y-%m-%d_%H:%M:%S`
MY_PID_FILE="${WORKING_DIR}/watchdog.pid"
#ps --pid `cat $MY_PID_FILE` -o cmd h | grep `basename $0` >/dev/null 2>&1 
ps --pid `cat $MY_PID_FILE` -o cmd h  >/dev/null 2>&1 
if [ $? -ne 0 ]; then
	# previrouse watchdog don't finished yet
	exit 0
fi				
echo  $$  > $MY_PID_FILE


CMD="timeout $TIMEOUT_GET_LS $RSYNC --list-only $REMOTE_SOURCE | /bin/egrep -i $VIDEO_EXT > $WORKING_DIR/ls.tmp"
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD
else
	$CMD
fi

# now we check if file don't changes during a minute 
if [ -f $WORKING_DIR/ls.tmp.old ]
else
	# first start
	mv $WORKING_DIR/ls.tmp $WORKING_DIR/ls.tmp.old
	exit 0
fi

IFS=$'\n'
for next in `cat $WORKING_DIR/ls.tmp`
do
	ID=`echo $next | /usr/bin/md5sum | awk '{ print $1 }'`
	if [ -d $DATA_DIR/$ID ]
		continue
	fi
	# check if this file exist more than 1 minute
	grep "$next" $WORKING_DIR/ls.tmp.old >/dev/null 2>&1
	if [  $? -ne 0  ]; then
		continue
	fi		
	mkdir $DATA_DIR/$ID
	FILENAME=`echo $next | awk '{ print $5 }'`
	CMD="$DIRNAME/send2queue.pl download '$DIRNAME/worker.sh $ID $REMOTE_SOURCE $FILENAME REMOTE_TARGET'"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Put job in queue: download file '$FILENAME' from '$REMOTE_SOURCE' to '$DATA_DIR/$ID'"
		$CMD >> $PROCESS_LOG 2>&1
	fi		
done 

mv $WORKING_DIR/ls.tmp $WORKING_DIR/ls.tmp.old


########## check failed jobs
# check worker jobs
for pid_file in  `find $DATA_DIR -name "*.worker.pid" -o -name "*.transcoder.pid"`; do
	ps --pid `cat $pid_file` -o cmd h >/dev/null 2>&1 
	if [ $? -ne 0 ]; then
		# failed job ( process crashed or killed )
		rm $pid_file
	fi		
done
# end of check

########## run jobs in the queues
# queue download
RUNNING_JOBS=`find $DATA_DIR -name "*.worker.pid" | wc -l`
for i in `seq $JOBS $JOBS_LIMIT_DOWNLOAD` ; do
	JOB=`$DIRNAME/send2queue.pl download`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done

# queue transcoder
RUNNING_JOBS=`find $DATA_DIR -name "*.transcoder.pid" | wc -l`
for i in `seq $JOBS $JOBS_LIMIT_TRANSCODER` ; do
	JOB=`$DIRNAME/send2queue.pl transcoder`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done
# end of job starter


########## run jobs
w2log "Job $$ finished successfully"
rm -rf $MY_PID_FILE
exit 0