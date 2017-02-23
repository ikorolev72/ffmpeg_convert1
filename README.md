#   queue for videofiles downloader, transcoder and uploader 

##  What is it?
This solution can help you get video file from one resource, transcode to specified format and upload to 
another resource. Can be run localy or on the remote site. 

* Version 1.3 2017.02.23

##  How?
There are 3 independed queue ( download, transcode, upload ), for every queue we can set max_jobs value.

Solution have main scripts:
	+	`job_starter.sh` ( check new files on remote server, check failed jobs, put new task to queue )
	+	`dowloader.sh` ( download new files and put tasks for transcoding to queue )
	+	`transcoder.sh` ( transcode files and put task for uploading into queue )
	+	`uploader.sh` ( upload transcoded files to remote host )
Almost all settings can be set in common.sh file
like JOBS_LIMIT_* , TIMEOUT for jobs, REMOTE_SOURCE, REMOTE_TARGET, etc
used relative paths for downloaded/uploaded files, also  special chars  and spaces into filenames  filxed to '_'

Download and upload use rsync ( for remote processes you need setup ssh keys ). 
Transcoding use ffmpeg.


### How to install? ###
This script require:
 + ffmpeg
 + rsync
 
Extract archive into any folder. Add strings 
```
*       *       *       *       *       /home/your_dir/job_starter.sh >> /home/your_dir/data/crontab.log 2>&1
0       0       1       *       *       /bin/mv -f /home/home_dir/data/ffmpeg_convert1.log /home/home_dir/data/ffmpeg_convert1.log.1  >> /home/home_dir/data/crontab.log 2>&1
0       0       10      *       *       /bin/mv -f /home/home_dir/data/ffmpeg_convert1.log /home/home_dir/data/ffmpeg_convert1.log.10  >> /home/home_dir/data/crontab.log 2>&1
0       0       20      *       *       /bin/mv -f /home/home_dir/data/ffmpeg_convert1.log /home/home_dir/data/ffmpeg_convert1.log.20  >> /home/home_dir/data/crontab.log 2>&1

``` 
into crontab.



### 		How to run
Change the value in file `common.sh` :
```
export PROJECT_DIR=/home/osboxes/ffmpeg_convert1
export REMOTE_SOURCE='/tmp/2/'
export REMOTE_TARGET='/tmp/2/transcoded-content/'
export JOBS_LIMIT_DOWNLOADER=3
export JOBS_LIMIT_TRANSCODER=5
export JOBS_LIMIT_UPLOADER=3
```


  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

