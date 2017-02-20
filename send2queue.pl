#!/usr/bin/perl
## This is a basic Producer
use strict;
use warnings;
use Carp;
use IPC::SysV qw(
    IPC_PRIVATE IPC_RMID IPC_CREAT S_IRWXU S_IRUSR
    S_IWUSR ftok IPC_STAT IPC_PRIVATE MSG_NOERROR);

my $queue_num=$ARGV[0];
my $queue_msg=$ARGV[1];
unless ( $queue_msg || $queue_num ) {
	print "Usage: $0 num_of_queue_not_zero 'message to queue'\n";
	print "Sample: $0 1 'message to queue'\n";
	exit(1);
}

# flush output
$| = 1;
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

my $n = 0;

#$SIG{INT} = sub {
#    print "Last n=$n\n";
#    exit 0;
#};
# start sending messages
#while(1) {
    my $mtype = 1;
    my $buffer_size = 200;
    $n++;
    my $buffer = $queue_msg;
    my $msg = pack('V V a200', $mtype, $buffer_size, $buffer);
    msgsnd( $ipc_id, $msg, 0);
exit(0);
#};
#sleep 30;
# dispose of the queue file
#unlink $queue_file;
