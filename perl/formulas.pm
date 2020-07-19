#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub average{
	my $data = shift;
	if (not @$data) {
			warn("Empty arrayn");
	}
	my $total = 0;
	foreach (@$data) {
			$total += $_;
	}
	my $average = $total / @$data;
	return $average;
}

sub stdev{
	my $data = shift;
	if(@$data == 1){
			return 0;
	}
	my $average = &average($data);
	my $sqtotal = 0;
	foreach(@$data) {
			$sqtotal += ($average-$_) ** 2;
	}
	my $std = ($sqtotal / (@$data-1)) ** 0.5;
	return $std;
}

1;