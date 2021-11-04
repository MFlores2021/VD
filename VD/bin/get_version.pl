#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;
use HTTP::Request;
use LWP::UserAgent;
require HTTP::Request;
use Data::Dumper;
use List::Util qw(max);

my $ftp_site     = 'http://bioinfo.bti.cornell.edu/';
my $ftp_dir     = 'ftp/program/VirusDetect/virus_database';

my $request = HTTP::Request->new(GET => $ftp_site . $ftp_dir)
    or die "Could not connect to $ftp_site: $!";
my $ua = LWP::UserAgent->new;
my $response = $ua->request($request);
my $sth = $response->content;

my @versions = $sth =~ m|<a href="v(.+?)/">v(.+?)/</a>|g;
my $folder = max(@versions); 

print "v" . $folder;
