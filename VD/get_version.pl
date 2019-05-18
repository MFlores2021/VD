#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;

my $ftp_site     = 'bioinfo.bti.cornell.edu';
my $ftp_dir     = 'pub/program/VirusDetect/virus_database';
my $glob         = 'v*';

my $ftp = Net::FTP->new($ftp_site) 
    or die "Could not connect to $ftp_site: $!";

$ftp->login() 
    or die "Could not login to $ftp_site with user  $!";

$ftp->cwd($ftp_dir) 
    or die "Could not change remote working " . 
             "directory to $ftp_dir on $ftp_site";

my @remote_files = $ftp->ls($glob);
my @sorted_files = reverse sort @remote_files;
my $folder = $sorted_files[0];

print $folder;

$ftp->quit();

# print "v229";

    



