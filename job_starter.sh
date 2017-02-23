#!/bin/bash
# korolev-ia [] yandex.ru
# This job_starter
# check the new files, check the queue and run tasks
# 

BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
. "$DIRNAME/common.sh"

#DEBUG=1


WORKING_DIR=$DATA_DIR/job_starter
PROCESS_LOG=$WORKING_DIR/job_starter.log
VIDEO_EXT='\.mp4$|\.avi$|\.mkv$|\.flv$|\.mov$'
EXCLUDE_DIRS='transcoded-content/|transfer33/|transfre/'

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

# check the new files on remote host
CMD="timeout $TIMEOUT_GET_LS $RSYNC -r --list-only $REMOTE_SOURCE" 
if [ "x$DEBUG" == "x1" ]; then
	echo $CMD  "| /bin/egrep -i $VIDEO_EXT | /bin/egrep -v $EXCLUDE_DIRS > $WORKING_DIR/ls.tmp"
else
	$CMD  | /bin/egrep -i $VIDEO_EXT | /bin/egrep -v $EXCLUDE_DIRS > $WORKING_DIR/ls.tmp
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


# put new job in the queue for every new file on remote source
IFS=$'\n'
for next in `$DIRNAME/same_strings.pl --f1=$WORKING_DIR/ls.tmp --f2=$WORKING_DIR/ls.tmp.old`
do
	# unique id - it is md5sum for string
	ID=`echo $next | /usr/bin/md5sum | awk '{ print $1 }'`
	if [ -d $DATA_DIR/$ID ]; then
		continue
	fi
	FILENAME=`echo $next  | /usr/bin/perl -ne '/^\S+\s+\S+\s+\S+\s+\S+\s+(.+)$/; print "$1" ;'`

	if [ "x$DEBUG" == "x1" ]; then
		echo ${DIRNAME}/send2queue.pl downloader "${DIRNAME}/downloader.sh $ID"
		echo "mkdir $DATA_DIR/$ID"
	else
		w2log "Put job in queue downloader: ${DIRNAME}/downloader.sh $ID"
		for i in `seq 4`; do		
			timeout 60 ${DIRNAME}/send2queue.pl downloader "${DIRNAME}/downloader.sh $ID" >> ${PROCESS_LOG} 2>&1
			if [  $? -eq 0  ]; then
				[ -d "${DATA_DIR}/${ID}" ] || mkdir -p "${DATA_DIR}/${ID}"

				JOB_SETTINGS_FILE=${DATA_DIR}/${ID}/job_settings.sh
				RELATIVE_DIR=`echo $FILENAME | /usr/bin/perl -ne '/^(.+\/)*(.+\.\w+)$/; my $filename=$1; $filename=~s/[^\w\/]+/_/g; print "$filename\n";'`
				OUTPUT_FILENAME=`echo $FILENAME | /usr/bin/perl -ne '/^(.+\/)*(.+\.\w+)$/; my $filename=$2; $filename=~s/[^\w\/\.]+/_/g; print "$filename\n";'`
				#OUTPUT_FILENAME=`echo $FILENAME | /usr/bin/perl -ne '/^(.+\/)*(.+)\.(\w+)$/; my $filename=$2; my $ext=$3; $filename=~s/^[\w\/\.]+/_/g; print "$filename.$ext";'`
				echo "export REMOTE_SOURCE_FILE='${REMOTE_SOURCE}/${FILENAME}'" > $JOB_SETTINGS_FILE
				echo "export DOWNLOAD_TO=${DATA_DIR}/${ID}/${RELATIVE_DIR}/${OUTPUT_FILENAME}" >> $JOB_SETTINGS_FILE
				echo "export RELATIVE_DOWNLOAD_TO=${RELATIVE_DIR}${OUTPUT_FILENAME}" >> $JOB_SETTINGS_FILE
				echo "export RELATIVE_DIR=${RELATIVE_DIR}" >> $JOB_SETTINGS_FILE	
				break
			fi
			w2log "Error: Cannot put job in queue downloader. See $PROCESS_LOG. Attempt $i"			
			let SLEEP_TIME=" 60 * $i " 
			sleep $SLEEP_TIME		
		done		
	fi			
done

rm -rf $MY_PID_FILE
exit 0


#
