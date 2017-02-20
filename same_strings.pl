#!/usr/bin/perl

use Getopt::Long;

$LOGFILE=STDERR;

GetOptions (
        'f1=s' => \$f1,
        'f2=s' => \$f2,
        "help|h|?"  => \$help ) or show_help();

show_help() if($help);

exit( 0 ) unless( -f $f1 );
exit( 0 ) unless( -f $f2 );

@a1=ReadFile2Array( $f1 );
@a2=ReadFile2Array( $f2 );


foreach $str ( @a1 ) {
	next if( $str=~/^\s*$/ ); # ignore empty strings
	print $str if( grep { $str eq $_} @a2 ) ;
}



sub get_date {
	my $time=shift() || time();
	my $format=shift || "%s-%.2i-%.2i %.2i:%.2i:%.2i";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
	$year+=1900;$mon++;
    return sprintf( $format,$year,$mon,$mday,$hour,$min,$sec);
}	


sub w2log {
	my $msg=shift;
	# daily log file
	my $log=shift;
	unless( $log ) {
		$log=$LOGFILE; 
	}
	open (LOG,">>$log") || print STDERR ("Can't open file $log. $msg") ;
	print LOG get_date()."\t$msg\n";
	print STDERR "$msg\n" if( $DEBUG );
	close (LOG);
}


sub ReadFile {
	my $filename=shift;
	my $ret="";
	open (IN,"$filename") || w2log("Can't open file $filename") ;
		while (<IN>) { $ret.=$_; }
	close (IN);
	return $ret;
}	

sub ReadFile2Array {
	my $filename=shift;
	my @data=();
	open (INFILE,"$filename") || w2log("Can't open file $filename") ;
		@data = <INFILE> ; 
	close INFILE ;
	return @data;
}	


					
sub WriteFile {
	my $filename=shift;
	my $body=shift;
	unless( open (OUT,">$filename")) { w2log("Can't open file $filename for write" ) ;return 0; }
	print OUT $body;
	close (OUT);
	return 1;
}	

sub AppendFile {
	my $filename=shift;
	my $body=shift;
	unless( open (OUT,">>$filename")) { w2log("Can't open file $filename for append" ) ;return 0; }
	print OUT $body;
	close (OUT);
	return 1;
}
					
sub show_help {
print STDERR "
Check two files and print only strings same in both files
Usage: $0  --f1=file1 --f2=file2 [--help]
";
	exit (1);
}					