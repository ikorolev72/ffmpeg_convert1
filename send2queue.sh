#!/bin/bash
# korolev-ia [] yandex.ru
# Send job to queue
# 

BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`
. "$DIRNAME/common.sh"

#DEBUG=1


WORKING_DIR=$DATA_DIR/queue
PROCESS_LOG=$WORKING_DIR/queue.log

if [ "x$DEBUG" == "x1" ]; then
	echo "mkdir -p '$WORKING_DIR'"
else
	[ -d "$WORKING_DIR" ] || mkdir -p "$WORKING_DIR"
fi	


QUEUE_NAME=$1
QUEUE_MSG=$2
DT=`date +%s`

# check the arguments
if [[ "x$QUEUE_NAME" == "x" ||  "x$QUEUE_MSG" == "x" ]] ; then
	echo "Usage:$0 queue_name 'queue_msg'"
	exit 1
fi	

QUEUE_FILE="${WORKING_DIR}/${QUEUE_NAME}.${DT}.$$"
cd $WORKING_DIR
echo $QUEUE_MSG > $QUEUE_FILE

sleep 1
if [ ! -f $QUEUE_FILE ]; then
	w2log "Queue file $QUEUE_FILE do not exist"
	exit 1
fi

exit 0



