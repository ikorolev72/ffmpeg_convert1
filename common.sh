# common settings
# variables and function

#DEBUG=1
export PROJECT_DIR=/home/osboxes/ffmpeg_convert1
export FFMPEG_DIR=/usr/bin
export REMOTE_SOURCE='/tmp/2/'
export REMOTE_TARGET='/tmp/3/'

if [ -d /home/hd25/stainlast12/ffmpeg_convert1 ]; then
	export PROJECT_DIR=/home/hd25/stainlast12/ffmpeg_convert1
	export FFMPEG_DIR=$PROJECT_DIR/ffmpeg-3.2.4-64bit-static
	export REMOTE_SOURCE='stainlast12@111.11.111.111:/usr/local/WowzaStreamingEngine/content/'
	export REMOTE_TARGET='stainlast12@111.11.111.111:/usr/local/WowzaStreamingEngine/transcoded/'
fi
export DATA_DIR=$PROJECT_DIR/data
export TIMEOUT_GET_FILE=3600 # 1hour
export TIMEOUT_TRANSCODE=3600 # 1hour
export TIMEOUT_PUT_FILE=3600 # 1hour
export TIMEOUT_GET_LS=60 # 1min
export JOBS_LIMIT_DOWNLOADER=3
export JOBS_LIMIT_TRANSCODER=3
export JOBS_LIMIT_UPLOADER=3

export RSYNC=/usr/bin/rsync
export LOG=$DATA_DIR/ffmpeg_convert1.log


w2log() {
	DATE=`date +%Y-%m-%d_%H:%M:%S`
		echo "$DATE $@"
		echo "$DATE $@" >> $LOG
	return 0
}


