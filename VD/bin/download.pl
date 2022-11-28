#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use Net::FTP;

my $org =$ARGV[0]; # 'plant';
my $filter = $ARGV[1]; #'U95';
my $version = $ARGV[2]; #'v229';
my $ftp_site = $ARGV[3]; #'http://bioinfo.bti.cornell.edu/ftp/program/VirusDetect/virus_database'

$ftp_site =~ s/\/$//;

my $site = $ftp_site . "/" . $version;
my $info = "vrl_genbank.info.gz";
my $info_old = "vrl_genbank_info.gz";
my $ids = "vrl_idmapping.gz";

my $url1 = $site  . "/" . $info;
my $url3 = $site  . "/" . $info_old;
my $url2 = $site  . "/" . $ids;

$version =~ s/v//;
my $db_file = $org . "_" . $version  . "_" . $filter .".tar.gz";
my $url4 = $site  . "/" . $filter ."/". $db_file;

getstore($url1, $info);
getstore($url2, $ids);
getstore($url3, $info);
getstore($url4, $db_file);

1;
