#!/usr/bin/perl
## This is a basic Consumer
use strict;
use warnings;
use Carp;
use IPC::SysV qw(
    IPC_PRIVATE IPC_RMID IPC_CREAT S_IRWXU S_IRUSR
    S_IWUSR ftok IPC_STAT IPC_PRIVATE MSG_NOERROR IPC_NOWAIT);
use Errno qw(:POSIX);
use Time::HiRes qw(usleep);
# flush output
$| = 1;

my $queue_num=$ARGV[0];
unless ($queue_num) {
	print "Usage: $0 num_of_queue_not_zero\n";
	print "Sample: $0 1\n";
	exit(1);
}
my $queue_file = "/tmp/ffmpeg_convert1.queue.$queue_num";

# create file (will be used to generate the 
open(my $fh,'>',$queue_file);
close($fh);

# use file to generate an IPC key value
my $msgkey = ftok($queue_file);

# check if the IPC key is defined
if(!defined $msgkey) {
    croak "couldn't generate IPC key value";
};

# create the message queue
my $ipc_id = msgget( $msgkey, IPC_CREAT | S_IRUSR | S_IWUSR );

my $qempty_tries_max = 1000;
my $qempty_tries = $qempty_tries_max;


# start sending messages

    my $msg;
    # read raw message from queue
    #
    # IPC_NOWAIT will cause msgrcv to not block and return immediately
    # with ENOMSG if there are no messages of that type in the message
    # queue.
    my $bytes_recv = msgrcv($ipc_id, $msg, 208, 0, IPC_NOWAIT);
    if($!{ENOMSG}) {
        $qempty_tries--;
        if($qempty_tries == 0) {
            # exit loop because we've exhausted the number of tries
            last;
        };
        # sleep 1% of a second (we're basically polling for
        # a new message on the queue. we give up if no message
        # is found and we exhaust the number of tries)
        usleep(1_000_000/100);
    } else {
        # refill tries if a message was present in the queue
        $qempty_tries = $qempty_tries_max;
    };

    # skip (no bytes received)
    exit(1) if $bytes_recv == 0;

    # split the message according to its format
    my ($mtype,$buffer_size,$buffer) = unpack("V V a200", $msg);

    print "$buffer\n";

# dispose of the queue file
#unlink $queue_file;
exit(0);