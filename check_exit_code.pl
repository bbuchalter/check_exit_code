#!/usr/bin/env perl

use warnings;
use strict;
use Getopt::Std;
use IO::File;

my $plugin_name = "Nagios log check";
my $VERSION = "1.0";

use constant EXIT_OK            => 0;
use constant EXIT_WARNING       => 1;
use constant EXIT_CRITICAL      => 2;
use constant EXIT_UNKNOWN       => 3;

my %opts;
getopts('f:t:', \%opts);
if (not (defined $opts{f} ) or not (defined $opts{t} )) {
        print "ERROR: invalid usage\n";
        HELP_MESSAGE();
        exit EXIT_UNKNOWN;
}

unless (-e $opts{f}) {
        print "ERROR: $opts{f} not found";
        exit EXIT_UNKNOWN;
}

my $status = EXIT_OK;
my $file_mod_time_in_days = -M $opts{f};
my $file_mod_time_in_minutes = sprintf( "%.2f", ($file_mod_time_in_days * 24 * 60) );


if ( $file_mod_time_in_minutes > $opts{t} ) {
        print "ERROR: $opts{f} last modified $file_mod_time_in_minutes minutes, threshold set to $opts{t} minutes\n";
        exit EXIT_CRITICAL;
}


my $fh = IO::File->new($opts{f}, O_RDONLY)
        or die 'Could not open file for reading.';

my $command_running = 1;

while( my $line = <$fh> ) {
        if ( $line =~ /Exit code:/ ) {
                if ( not $line =~ /Exit code: 0/ ) {
                        PRINT_EXIT_CODE($line);
                        exit EXIT_CRITICAL;
                }
                $command_running = 0;
        }
}

close $fh;

if ($command_running == 1) {

        print "Command currently running...";
} else {

        print "Command completed successfully about $file_mod_time_in_minutes minutes ago.\n";

}


exit $status;


sub PRINT_EXIT_CODE {


        my $error_codes = {
        };

        my $unparsed_exit_code;
        $unparsed_exit_code = $_[0];

        my @split_exit_code = split(" ", $unparsed_exit_code);
        my $exit_code = $split_exit_code[-1];
        print "Exit code $exit_code: ";
        print $error_codes->{$exit_code} || "UNKNOWN ERROR";
}

sub HELP_MESSAGE 
{
        print <<EOHELP
        Check log output has been modified with t minutes and contains "Exit code: 0".
        If "Exit code" is not found, assume command is running.
        Check assumes the log is truncated after each command is run.
        
        --help      shows this message
        --version   shows version information

        -f          path to log file
        -t          Time in minutes which a log file can be unmodified before raising CRITICAL alert

EOHELP
;
}

sub VERSION_MESSAGE 
{
        print <<EOVM
$plugin_name v. $VERSION
Copyright 2012, Brian Buchalter - Licensed under GPLv2
EOVM
;
}
