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
VIDEO_EXT="'.mp4$|.avi$|.mkv$'"

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


CMD="timeout $TIMEOUT_GET_LS $RSYNC --list-only $REMOTE_SOURCE | /bin/egrep -i $VIDEO_EXT > $WORKING_DIR/ls.tmp"
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD
else
	$CMD
fi

# now we check if file don't changes during a minute 
if [ ! -f $WORKING_DIR/ls.tmp.old ]; then
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
	CMD="$DIRNAME/send2queue.pl downloader '$DIRNAME/downloader.sh $ID $REMOTE_SOURCE $FILENAME REMOTE_TARGET'"
	if [ "x$DEBUG" == "x1" ]; then
		echo $CMD 
	else
		w2log "Put job in queue: downloader file '$FILENAME' from '$REMOTE_SOURCE' to '$DATA_DIR/$ID'"
		$CMD >> $PROCESS_LOG 2>&1
	fi		
done 

mv $WORKING_DIR/ls.tmp $WORKING_DIR/ls.tmp.old


########## check failed jobs
# check downloader jobs
for pid_file in  `find $DATA_DIR -name '*.downloader.pid' -o -name '*.transcoder.pid'  -o -name '*.uploader.pid'`; do
	ps --pid `cat $pid_file` -o cmd h >/dev/null 2>&1 
	if [ $? -ne 0 ]; then
		# failed job ( process crashed or killed )
		rm $pid_file
	fi		
done
# end of check

########## run jobs in the queues
# queue downloader
RUNNING_JOBS=`find $DATA_DIR -name "*.downloader.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_DOWNLOADER` ; do
	JOB=`$DIRNAME/send2queue.pl downloader`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done

# queue transcoder
RUNNING_JOBS=`find $DATA_DIR -name "*.transcoder.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_TRANSCODER` ; do
	JOB=`$DIRNAME/send2queue.pl transcoder`
	if [ $? -ne 0 ]; then
		# queue is empty
		break
	fi
	$JOB >> $PROCESS_LOG 2>&1 &
done
# queue uploader
RUNNING_JOBS=`find $DATA_DIR -name "*.uploader.pid" | wc -l`
for i in `seq $RUNNING_JOBS $JOBS_LIMIT_UPLOADER` ; do
	JOB=`$DIRNAME/send2queue.pl uploader`
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