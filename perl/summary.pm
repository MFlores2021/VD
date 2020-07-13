#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub create_html {
	my $dir = shift;
	my $spike = shift;
	my @files = @_;

	my $sum_file = catfile($dir,"Summary.tsv");	
	my @spikes = split /,/, $spike;
	# print Dumper \@files;
	# print Dumper $spike;
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
			<script src="https://code.jquery.com/jquery-3.5.1.js"></script>
			<script src="https://cdn.datatables.net/1.10.21/js/jquery.dataTables.min.js"></script>
			<script src="https://cdn.datatables.net/1.10.21/js/dataTables.bootstrap4.min.js"></script>
			<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/css/bootstrap.css">
			<link rel="stylesheet" href="https://cdn.datatables.net/1.10.21/css/dataTables.bootstrap4.min.css">
		</head>
		<body>
		<script>
			$(document).ready(function() {
				$("#sumTable").DataTable({
					scrollX : true,
					responsive : true;
				});
			} );
		</script>
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
		<h3>Results</h3><br>
  ';
	
	foreach my $file (@files){
		_print_name($file,$fh);
	}
	_print_table($fh,$sum_file);
	
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

sub _print_table {
	my $fh = shift;
	my $sum_file = shift;
	
	my $table = '<div class="row"><div class="col-lg-12">';

	$table .= '<table class="table table-striped table-bordered table-hover" width="100%" id="sumTable" style="width:100%">';

	open(FILE,$sum_file) || die "WRONG FILE";
		my (@data,@data_n);
				
		while(my $line = <FILE>){
			chomp $line;
			next if $line =~ /^\s*$/;
			if ($line =~ /^File/){ $table .= '<thead>'; }
			$table .= '<tr>';
			my @col = split(/\t/,$line);
			
			foreach(@col){
				if ($line =~ /^File/){ $table .= '<th>' . $_ . '</th>'; }
				else { $table .= '<td>' . $_ . '</td>' };
			}
			
			if ($line =~ /^File/){ $table .= '</thead>'; }
			$table .= '</tr>';
		}
	$table .= '</table>';
	$table .= '</div></div>';
	print $fh $table . "\n";

}
sub _print_summaries {
	my $dir = shift;
	my $fh = shift;
	
	print $fh "Trimming graph";
	print $fh "<img src='Trimming_graph.png' /><br>";
	print $fh "Spike in graph";
	print $fh "<img src='spike_sum.png' /><br>";
	print $fh "Norm spike in graph";
	print $fh "<img src='norm_spike_sum.png' />";
}

sub _print_detail {
	my $file = shift;
	my $fh = shift;
	my $counter = shift;
	
	my $org_file = $file;
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
		  <div class="panel-body">Clean reads
		  <img src="'. $file . '.clean_reads.png" /><br>
		  <embed type="text/html" src="result_' . $org_file . '/blastn.html" width="500" height="500">
		  </div>
		</div>
	  </div>
	</div> ';

	print $fh $content;
}

1;