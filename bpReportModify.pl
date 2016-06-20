#!/usr/local/bin/perl -w

# AJP 25/02/09 
# This script will take the Netbackup status code report and format it to make it more readable
# It is called by the file /usr/openv/netbackup/bin/goodies/mail_bp_reports

use strict;

open INPUT,"$ARGV[0]" or die "Can't open $ARGV[0] file: $!\n";

print "\nThis backup report displays the status codes of all backups that ran in the last 24 hours, i.e the 24 hour period ending: " . `date +"%H:%M %d/%m/%y"`;

print "\nThe format is:\n\n"; 
print "STATUS CODE - DESCRIPTION:\n";
print "list of hosts reporting that status code\n\n\n";
print "For details of when the status codes were reported refer to the 'NetBackup backup status' email sent out at 9am each day\n\n";
print "--------------------------------------------------------------------------------\n";

while (<INPUT>) {
	if ($_ =~ m/^\s+$/) {
		next;
	}
	elsif ($_ =~ m/^\s*(\d+)\s+([a-zA-Z]+.*$)/) {
		chomp (my $tmpstrg=$2);
		print "\n\n$1 - " . uc($2) . ":\n\n"; 
	}
	elsif ($_ =~ m/^(\s+[a-z][a-z0-9.-_]+\s*)+/) {
		my @hosts=split ' ', $_;
       		foreach (@hosts) {
               		print "$_\n";
            	}
	}
	elsif ($_ =~ m/Recently\sUsed\sMedia/) {
		print "\n\n\n$_";
	}
	else {
		print "$_";
	}
}
