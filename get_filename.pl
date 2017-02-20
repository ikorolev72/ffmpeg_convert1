#!/usr/bin/perl

my $in=$ARGV[0];
my $ext=$ARGV[1];
exit(1)  unless( $in ) ;
exit(1)  unless( $ext ) ;


#if( $in=~/^(.+)\.{avi|mp4|mkv}\.${ext}$/i) 
if( $in=~/^(.+)\.\w+\.$ext$/) 
	{ 
		print "${1}_${ext}.mp4";
		exit 0;
	} 
	else 
	{ 
		exit 1 ;
	}
