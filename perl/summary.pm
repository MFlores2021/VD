#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub create_html {
	my $dir = shift;
	my $spike = shift;
	my @files = @_;
	
	my @spikes = split /,/, $spike;
	print Dumper \@files;
	print Dumper $spike;
	print scalar @spikes;
	open my $fh, '>', catfile($dir,"Summary.html") or warn "couldn't open: $!";
	
	print $fh '<!DOCTYPE html>
		<html>
		<head>
		<title>VDW</title>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
		<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
		<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>
		</head>
		<body>
		<style type="text/css">
		@media all {
			.lightbox { display: none; }
		}
		.panel-heading a:after {
		content:"\e114";
		float: right;
		color: grey;
		}
		.panel-heading a.collapsed:after {
			content:"\e080";
		}
		</style>
  ';
	
	foreach my $file (@files){
		_print_name($file,$fh);
	}
	
	_print_summaries($dir,$fh);
	
	my $counter = 1;
	foreach my $file (@files){
		_print_detail($file,$fh,$counter);$counter++;
	}
	
	return 1;
}

sub _print_name {
	my $file = shift;
	my $fh = shift;
	print $fh $file . "\n";
}

sub _print_summaries {
	my $dir = shift;
	my $fh = shift;
	
	print $fh "Trimming graph";
	print $fh "<img src='Trimming_graph.png' />";
}

sub _print_detail {
	my $file = shift;
	my $fh = shift;
	my $counter = shift;
	
	$file =~ s/.fastq//;
	$file =~ s/.fq//;

			
	my $content = '<div class="panel-group">
	  <div class="panel panel-default">
		<div class="panel-heading">
		  <h4 class="panel-title">
			<a data-toggle="collapse" href="#h-'. $counter . '">' . $file . '</a>
		  </h4>
		</div>
		<div id="h-'. $counter . '" class="panel-collapse collapse">
		  <div class="panel-body">Panel Body
		  <img src="'. $file . '.clean_reads.png" />
		  </div>
		</div>
	  </div>
	</div> ';

	print $fh $content;
}

1;