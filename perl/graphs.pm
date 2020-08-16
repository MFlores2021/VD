#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use File::Spec::Functions 'catfile';
use File::Path;
use GD;
use GD::Graph::bars;
use GD::Graph::Data;
use GD::Graph::lines;
use GD::Graph::points;
use Scalar::Util qw(looks_like_number);

sub graph_spiking_sum {
	my $dir = shift;
	my $spike = shift;
	
	my $sum_file = catfile($dir ,'Summary.tsv');
	
	my @spikes = split /,/, $spike;
	my $spikes = scalar(@spikes);
	
	if (-e -s $sum_file && $spikes > 0){
		
		my (@spike_col,@spike_col_n);
		my @fastq;
		my $column=8;
		my $column_n=$column-1;
		for (0 .. $spikes-1){
			push @spike_col, $column+($_*2);
			push @spike_col_n, $column_n+($_*2);
		}
	
		open(FILE,$sum_file) || die "WRONG FILE";
		my (@data,@data_n);
		my $max = 0;
		my $max_n = 0;
		
		while(my $line = <FILE>){
			my (@value,@value_n);
			chomp $line;
			next if $line =~ /^\s*$/;
			
			my @line = split(/\t/,$line);
			
			push @fastq, $line[0] if (!($line =~ /^File/));
			foreach(@spike_col){
				$line[$_] =~ s/#\ Spikes:\ //g;
				push @value, $line[$_];
				if(looks_like_number($line[$_]) && $max < $line[$_]) { $max = $line[$_]; }
			}
			foreach(@spike_col_n){
				$line[$_] =~ s/Norm.\ Spike:\ //g;
				push @value_n, $line[$_];
				if(looks_like_number($line[$_]) && $max_n < $line[$_]) { $max_n = $line[$_]; }
			}
			push @data, [@value];
			push @data_n, [@value_n];
		}
	
		my $result = _draw_lines(\@data,$dir, 'Spikes summary','spike_sum.png',\@fastq,$max);
		my $result_n = _draw_lines(\@data_n,$dir,'Normalized spikes summary','norm_spike_sum.png',\@fastq,$max_n);
	}
	return 1;
}

sub graph_cumulative_clean_sum{
	my $dir = shift;

	my $sum_file = catfile($dir ,'report_sRNA_trim.txt');
	
	if (-e -s catfile($dir ,'report_sRNA_trim.txt')){

		open(FILE,$sum_file) || die "WRONG FILE";
		my (@data,@data_n);
		my $max = 0;
		my $max_n = 0;
		my @col = (0,8,5,7,6,3,2);
		my @col_names = ("cleaned reads", "contains N", "long reads", "short reads", "adapter only","no adapter");
				
		while(my $line = <FILE>){
			chomp $line;
			next if $line =~ /^\s*$/;
			my @line = split(/\t/,$line);
			my @value;
			
			foreach(@col){
				push @value, $line[$_];
				if(looks_like_number($line[$_]) && $max < $line[$_]) { $max = $line[$_]; }
			}
			push @data, [@value];
		}
		for my $row (0..@data-2){
			for my $col (0..@{$data[$row]}-1){
				$data_n[$col][$row] = $data[$row+1][$col];
			}
		}

		my $result = _draw_bars(\@data_n,$dir,'Cleanning statistics','trimming_graph.png',\@col_names);

	}
}

sub graph_size{
	my $dir = shift;
	
	if (-e -s catfile($dir ,'sRNA_length.txt')){
		open FILE , catfile($dir ,'sRNA_length.txt') or die;
		my $line = <FILE>;
		my @field = split /\t/, $line;

		my $datax =GD::Graph::Data-> new() or die;
		$datax->read(file => catfile($dir ,'sRNA_length.txt'), delimiter => '\t');

		foreach my $i (1..$datax->num_sets()){
			my $data = $datax->copy();
			$data -> wanted($i);
			my $graph = GD::Graph::lines->new(450,400);

			$graph->set(
				x_label         => 'Read size',
				y_label         => 'Frequency',
				x_labels_vertical => 1,
				title           => $field[$i],
				transparent     => 0,
				fgclr        => 'black',
				boxclr       => 'white',
				box_axis	=>0,
				x_label_position=>.5,
				b_margin=>10,
				t_margin=>10,
				l_margin=>10,
				r_margin=>10,
				accentclr    => 'white',
			) or die $graph->error;
		  
			$graph->set_legend_font('gdMediumBoldFont', 20);
			$graph->set_title_font('gdMediumBoldFont');
			$graph->set_y_label_font(gdMediumBoldFont);
			$graph->set_x_label_font(gdMediumBoldFont);
			$graph->set_values_font(gdMediumBoldFont);
			$graph->plot($data) or die $graph->error;

			my $file = catfile($dir ,trim($field[$i]).'_reads.png');
			open(my $out, '>', $file) or die "Cannot open '$file' for write: $!";
			binmode $out;
			print $out $graph->gd->png;
			close $out;
		}
	}
}

sub _draw_lines {
	my $data = shift;
	my $dir = shift;
	my $title = shift;
	my $out_name = shift;
	my $fastq = shift;
	my $max = shift;
	my @fastq = @$fastq;

	my $graph = GD::Graph::lines->new(400,450);

	$graph->set(
		x_label         => 'Spike in',
		y_label         => 'Frequency',
		x_labels_vertical => 1,
		y_max_value		=> $max+10,
		y_tick_number	=> 10,
		y_number_format => sub {int(shift);},
		title           => $title,
		transparent     => 0,
		fgclr        => 'black',
		boxclr       => 'white',
		box_axis	=>0,
		x_label_position=>.5,
		b_margin=>10,
		t_margin=>10,
		l_margin=>10,
		r_margin=>10,
		accentclr    => 'white',
	) or die $graph->error;

	$graph->set_legend(@fastq);
	$graph->set_legend_font('gdMediumBoldFont', 20);
	$graph->set_title_font('gdGiantFont');
	$graph->set_y_label_font('gdMediumBoldFont');
	$graph->set_x_label_font('gdMediumBoldFont');
	$graph->set_values_font('gdMediumBoldFont');
	$graph->plot($data) or die $graph->error;

	my $file = catfile($dir , $out_name);
	open(my $out, '>', $file) or die "Cannot open '$file' for write: $!";
	binmode $out;
	print $out $graph->gd->png;
	close $out;
	
	return 1;
}

sub _draw_bars {
	my $table = shift;
	my $dir = shift;
	my $title = shift;
	my $out_name = shift;
	my $x = shift;
	my @x_axes = @$x;

	my $graph = GD::Graph::bars->new(500,600);

	$graph->set(
			y_label         => 'Frequency',
			x_labels_vertical => 1,
			title           => $title,
			cumulate		=> 1,
			transparent     => 0,
			bar_spacing		=>10,
			fgclr        	=> 'black',
			boxclr       	=> 'white',
			box_axis		=>0,
			x_label_position=>.5,
			b_margin		=>10,
			t_margin		=>10,
			l_margin		=>10,
			r_margin		=>10,
			accentclr    	=> 'white',
			dclrs			=> ['green','lblue','pink','lyellow', 'orange','lred'],

	) or die $graph->error;
	
	$graph->set_legend(@x_axes);
	$graph->set_legend_font('gdMediumBoldFont', 20);
	$graph->set_title_font('gdGiantFont');
	$graph->set_y_label_font('gdMediumBoldFont');
	$graph->set_x_label_font('gdMediumBoldFont');
	$graph->set_values_font('gdMediumBoldFont');
	$graph->plot($table) or die $graph->error;

	my $file = catfile($dir , $out_name);
	open(my $out, '>', $file) or die "Cannot open '$file' for write: $!";
	binmode $out;
	print $out $graph->gd->png;
	close $out;
	
	return 1;
}


sub trim { my $s = shift; if($s){ $s =~ s/^\s+|\s+$//g; }; return $s };


1;