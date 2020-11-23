#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use File::Basename;

sub create_html {
	my $dir = shift;
	my $spike = shift;
	my $files = shift;
	my $control_cutoff = shift;
	my $average= shift;
	my $sd = shift;
	my $constant = shift;
	
	my @files = @$files;

	my $sum_file = catfile($dir,"Summary.tsv");	
	my @spikes = split /,/, $spike;

	open my $fh, '>', catfile($dir,"Summary.html") or warn "could not open: $!";
	
	print $fh '<!DOCTYPE html>
		<html>
		<head>
			<title>VDW</title>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
			<script src="https://code.jquery.com/jquery-3.5.1.js"></script>
			<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
			<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js" integrity="sha384-OgVRvuATP1z7JjHLkuOU7Xw704+h835Lr+6QL9UvYjZE3Ipu6Tp75j7Bh/kR0JKI" crossorigin="anonymous"></script>
			
			<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
			<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

			<script src="https://cdn.datatables.net/1.10.21/js/jquery.dataTables.min.js"></script>
			<script src="https://cdn.datatables.net/1.10.21/js/dataTables.bootstrap4.min.js"></script>
			<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/css/bootstrap.css">
			<link rel="stylesheet" href="https://cdn.datatables.net/1.10.21/css/dataTables.bootstrap4.min.css">
		</head>
		<body>
		<script>
			$(document).ready(function() {
				$("#sumTable").DataTable({
					"lengthMenu": false,            
                    "bLengthChange": false,
                    "scrollX": true,
                    "scrollY": false,
                    "responsive": true
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

		<header><br><h2 style="text-align: center">Summary</h2>
		</header>
		<main role="main">
			<div class="container marketing">
		       
  ';
	
	# foreach my $file (@files){
	# 	_print_name($file,$fh);
	# }
	_print_table($fh,$sum_file,$control_cutoff,$average,$sd,$constant);
	_print_cleaning_summaries($dir,$fh);
	_print_spike_summaries($dir,$fh);
	
	my $counter = 1;
	if (scalar(@files)>0){
		my $detail = '<div class="row featurette">
			          <div class="col-md-12">
			            <h2 class="featurette-heading">Samples detail</h2>
			            <p class="lead">Identification of viral sequences is critically dependent upon the quality of the database(s) used. The default databases used by VDW contain all sequences annotated as viral from a certain host order that are available from Genbank. As a result some host derived proteins can be misidentified as viral because some viral proteins are related to host proteins. Typical examples in plants are heat shock (Hsp70) proteins found in closteroviruses, or reverse transcriptases of Caulimoviridae that are homologous to those of retrotransposons. Wrongly annotated sequences in the public databases can also lead to misinterpretation of findings, e.g. some sequences annotated as viral actually correspond to host proteins. When unexpected or uncertain results are obtained, a first check should be to click the link to the source sequence accession in Genbank and perform a BLAST with that sequence against the entire Genbank. This can quickly reveal if the sequence in question is misannotated Genbank or a sequence that may have homology to host DNA.</p>
			          </div><div class="col-md-12">';
		print $fh $detail;

		foreach my $file (@files){
			_print_detail($file,$fh,$counter,$dir);$counter++;
		}

		$detail = '</div>
		      </div>
		      <hr class="featurette-divider">';
		print $fh $detail;
	}

	print $fh '<footer class="container">
	        <p class="float-right"><a href="#">Back to top</a></p>
	        <p>&copy; 2020 VDW &middot; <a href="#">Privacy</a> &middot; <a href="#">Terms</a></p>
	      </footer>
	    </div></main>
	    </body>
	</html>';

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
	my $control_cutoff = shift;
	my $average = shift;
	my $sd = shift;
	my $times_sd = shift;

	my $table = '<div class="row" id="summary">
		          <h2 class="featurette-heading">Summary report</h2><div class="container">';
	if ($control_cutoff){
		$table .= 'Average contamination from control virus: '. sprintf("%.4f",$average) .'; SD: <b>' . sprintf("%.4f",$sd) . '</b><br>';
		$table .= 'Control cutoff (Average + '. $times_sd .' *SD): ' . sprintf("%.4f",$control_cutoff);
		$table .= "<br>The control cutoff value can be used to determine an expected contamination rate of highly abundant reads of a virus identified from one sample to any other sample of a pooled library and is based on the detected contamination from the sample with your control virus (when included) throughout the pooled library. Use it by multiplying the control cutoff value with the \'Depth (Norm)\' value of any virus with high \'Depth (Norm\' values identified in any sample, which will provide you a ‘Depth (Norm)’ you could expect of that same virus in other samples based purely on contamination and could thus represent false positives.";
	}
	
	$table .= '<table class="table table-striped table-bordered table-hover display nowrap" width="100%" id="sumTable" style="width:100%">';

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
	$table .= '</table></div>';
	$table .= '</div>
		       <hr class="featurette-divider">';
	print $fh $table . "\n";

}

sub _print_cleaning_summaries {
	my $dir = shift;
	my $fh = shift;
	my $figures = "";
	
	if (-e -s catfile($dir,"Trimming_graph.png")) {
		$figures = '<div class="row featurette">
					  <div class="col-md-4">
						<h2 class="featurette-heading">Cleaning summary</h2>
						<p class="lead">.</p>
					  </div>';

		$figures .= '<div class="col-md-8">
					<img class="featurette-image img-fluid mx-auto" src="Trimming_graph.png" alt="Generic placeholder image">
				   </div>
				  </div>
				  <hr class="featurette-divider">';
	}
	
	print $fh $figures;
}

sub _print_spike_summaries {
	my $dir = shift;
	my $fh = shift;
	my $figures = "";
	if (-e -s catfile($dir,"spike_sum.png") && -e -s catfile($dir,"norm_spike_sum.png") ){
		$figures = '<div class="row featurette">
					  <div class="col-md-12">
						<h2 class="featurette-heading">Spikes summary</h2>
						<p class="lead">.</p>
					  </div>';

		$figures .= '<div class="col-md-6">
					<img class="featurette-image img-fluid mx-auto" src="spike_sum.png" alt="Generic placeholder image">
				   </div>';
		$figures .= '<div class="col-md-6">
					<img class="featurette-image img-fluid mx-auto" src="norm_spike_sum.png" alt="Generic placeholder image">
				   </div>
				  </div>
				  <hr class="featurette-divider">';
	}
	print $fh $figures;
}

sub _print_detail {
	my $pathfile = shift;
	my $fh = shift;
	my $counter = shift;
	my $dir = shift;
	
	my $file = basename($pathfile);
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
	  <div class="panel-body">';
	
	#Print reads size
	$file =~ s/.clean//;
	my $file_clean = catfile($dir,$file . '_reads.png');
	if (-e -s $file_clean){
		$content .= '<h3>Clean reads</h3><br>
			  <img width="80%" src="'. $file . '_reads.png" /><br>';
	}

	#Create link to fastqc
	my $file_fastqc = catfile($dir,$file . '_fastqc.html');
	if (-e -s $file_fastqc){
		$content .= '<a href="'. $file_fastqc .'" target="_blank">FastQC report</a><br>';
	}
	
	#Print blastn
	my $file_blastn = catfile($dir,'result_' . $org_file ,'blastn.html');
	if (-e -s $file_blastn){
		$content .= '<h3>BLASTN results </h3><br>
					<embed type="text/html" src="result_' . $org_file . '/blastn.html" width="100%" height="500">';
	}
	
	#Print blastx
	my $file_blastx = catfile($dir,'result_' . $org_file ,'blastx.html');
	if (-e -s $file_blastx){
		$content .= '<h3>BLASTX results </h3><br>
					<embed type="text/html" src="result_' . $org_file . '/blastx.html" width="100%" height="500">';
	}
	
	$content .=  '</div>
		</div>
	  </div>
	</div> ';

	print $fh $content;
}

1;