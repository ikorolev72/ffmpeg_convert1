# common settings
# variables and function

#DEBUG=1
export PROJECT_DIR=/home/osboxes/ffmpeg_convert1
export FFMPEG_DIR=/usr/bin
export REMOTE_SOURCE='/tmp/2/'
export REMOTE_TARGET='/tmp/2/transcoded-content/'

if [ -d /home/hd25/stainlast12/ffmpeg_convert1 ]; then
	export PROJECT_DIR=/home/hd25/stainlast12/ffmpeg_convert1
	export FFMPEG_DIR=$PROJECT_DIR/ffmpeg-3.2.4-64bit-static
	#export REMOTE_SOURCE='transfer33@185.25.48.253:/etc/video/test/'
	export REMOTE_SOURCE='/home/hd25/stainlast12/torrents/data/'	
	export REMOTE_TARGET='transfer33@185.25.48.253:/etc/video/transcoded-content/'
fi
export DATA_DIR=$PROJECT_DIR/data
export TIMEOUT_GET_FILE=3600 # 1hour
export TIMEOUT_TRANSCODE=7200 # 2hours
export TIMEOUT_PUT_FILE=3600 # 1hour
export TIMEOUT_GET_LS=120 # 1min
export JOBS_LIMIT_DOWNLOADER=3
export JOBS_LIMIT_TRANSCODER=5
export JOBS_LIMIT_UPLOADER=3

export TRANSCODE_FORMATS_LIST='320 640 400 700 1100 1300 1500 175k'

export RSYNC="/usr/bin/rsync --rsh=ssh "
export LOG=$DATA_DIR/ffmpeg_convert1.log


w2log() {
	DATE=`date +%Y-%m-%d_%H:%M:%S`
		#echo "$DATE $@"
		echo "$DATE $@" >> $LOG
	return 0
}


