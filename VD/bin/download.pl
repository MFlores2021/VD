#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use Net::FTP;

my $org =$ARGV[0]; # 'plant';
my $filter = $ARGV[1]; #'U95';
my $version = $ARGV[2]; #'v229';
my $ftp_site     = 'bioinfo.bti.cornell.edu';
my $ftp_dir     = 'pub/program/VirusDetect/virus_database';
my $glob         = 'v*';
my $glob2         = '*gz';

my $ftp = Net::FTP->new($ftp_site) 
    or die "Could not connect to $ftp_site: $!";

$ftp->login() 
    or die "Could not login to $ftp_site with user  $!";

my $site=$ftp_dir . "/" . $version. "/" . $filter;
$ftp->cwd($site) 
    or die "Could not change remote working " . 
             "directory to $site";

my @remote_files2 = $ftp->ls($glob2);

foreach my $file (@remote_files2) {
	if ( $file =~ m/\Q$org/is ) {
        my $url = "ftp://" .$ftp_site . "/" . $ftp_dir . "/" . $version  . "/" . $filter . "/" . $file ;

		getstore($url, $file);
		print "$file";
	}
}
my $info = "vrl_genbank_info.gz";
my $ids = "vrl_idmapping.gz";
my $url1 = "ftp://" .$ftp_site . "/" . $ftp_dir . "/" . $version  . "/" . $info ;
my $url2 = "ftp://" .$ftp_site . "/" . $ftp_dir . "/" . $version  . "/" . $ids ;
getstore($url1, $info);
getstore($url2, $ids);

$ftp->quit();

    # print "plant_229_U95.tar.gz";



