#!/bin/bash
# korolev-ia [] yandex.ru
# Get message fifo from queue
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
# check the arguments
if [[ "x$QUEUE_NAME" == "x" ]] ; then
	echo "Usage:$0 queue_name"
	exit 1
fi	

cd $WORKING_DIR

QUEUE_FILE=`ls -1 ${WORKING_DIR}/${QUEUE_NAME}.* 2>/dev/null | sort | head -1` 
if [ -f "$QUEUE_FILE" ]; then
	cat "${QUEUE_FILE}" 
	rm -f "${QUEUE_FILE}"
	exit 0
fi

# empty queue
exit 1

