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

sub create_spiking_sum {
	my $dir = "C:\\Users\\mire_\\VDW\\results\\testjune";
	my $spike = "ac,acan,cajac";
	
	my @spikes = split /,/, $spike;
	my $spikes = scalar(@spikes);
	
	if (-e -s catfile($dir ,'Summary.tsv') && $spikes > 0){
		
		# Draw spikes
		my $data = GD::Graph::Data-> new() or die;
		$data->read(file => catfile($dir ,'Summary.tsv'), delimiter => '\t');
		my @spike_col;
		my $column=8;
		for (0 .. $spikes-1){ push @spike_col, $column+($_*2);}
		$data->wanted(@spike_col);
		my $result = _draw_lines($data,$dir,'Spike in summary','spike_sum.png',\@spikes);
		
		# Draw Norm Spikes
		my $data_n = GD::Graph::Data-> new() or die;
		$data_n->read(file => catfile($dir ,'Summary.tsv'), delimiter => '\t');
		my @spike_col_n;
		my $column_n=7;
		for (0 .. $spikes-1){ push @spike_col_n, $column_n+($_*2);}
		$data_n->wanted(@spike_col_n);
		my $result_n = _draw_lines($data_n,$dir,'Normalized spike in summary','norm_spike_sum.png',\@spikes);
	}
	return 1;
}

sub graph_cumulative_clean_reads{
	my $dir = "C:\\Users\\mire_\\VDW\\results\\testjune";
	
	if (-e -s catfile($dir ,'report_sRNA_trim.txt')){

		my @col;
		open my $handle, '<', catfile($dir ,'report_sRNA_trim.txt');
		chomp (my @lines = <$handle>);
		close $handle;
	#print Dumper \@lines;
		my $result = _draw_bars(\@lines,$dir,'Cleanning statistics','trimming_graph.png',\@col);

	}
}

sub _draw_lines {
	my $data = shift;
	my $dir = shift;
	my $title = shift;
	my $out_name = shift;
	my $spikes = shift;
	my @spikes = @$spikes;

	my $graph = GD::Graph::lines->new(600,900);
	my $max = $data->get_min_max_y_all(); print Dumper \$max;

	$graph->set(
		x_label         => 'Samples',
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
	
	$graph->set_legend(@spikes);
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
	my $data = shift;
	my $dir = shift;
	my $title = shift;
	my $out_name = shift;
	my $x = shift;
	my @x_axes = @$x;

	my $graph = GD::Graph::bars->new(800,1200);
	my $max = $data->get_min_max_y_all()->[1]; print Dumper $max;

	$graph->set(
			x_label         => 'Samples',
			y_label         => 'Frequency',
			x_labels_vertical => 1,
			title           => $title,
			cumulate		=> 1,
			transparent     => 0,
			bar_spacing		=>50,
			fgclr        	=> 'black',
			boxclr       	=> 'white',
			box_axis		=>0,
			x_label_position=>.5,
			b_margin		=>10,
			t_margin		=>10,
			l_margin		=>10,
			r_margin		=>10,
			accentclr    	=> 'white',
	) or die $graph->error;
	
	$graph->set_legend(@x_axes);
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

sub trim { my $s = shift; if($s){ $s =~ s/^\s+|\s+$//g; }; return $s };

create_spiking_sum();
graph_cumulative_clean_reads();
1;