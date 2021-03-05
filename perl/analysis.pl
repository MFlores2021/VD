#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use File::Spec::Functions 'catfile';
use File::Path;
use File::Basename;
use List::MoreUtils qw(first_index);
use Cwd qw(getcwd);
use Data::Dumper;
use lib catfile("VD","bin");
use Util;
use align;
use summary;
use graphs;
use formulas;

my $localdir = getcwd;

my $dir = $ARGV[0]; 
my $spike = $ARGV[1]; #'U95';
my $adaptor = $ARGV[2]; #'v229';
my $length  = $ARGV[3];
my $max_length  = $ARGV[4];
my $database = $ARGV[5];
my $host  = $ARGV[6];
my $cores = $ARGV[7];
my $controlseq = $ARGV[8];
my $controlfile = $ARGV[9];
my $controlconst = $ARGV[10];
my $rmdup = $ARGV[11];
my $add_parameters = $ARGV[12]; 

my $BIN_DIR  = catfile("VD","bin"); 
my $align_program    = catfile("$BIN_DIR","bwa");
my $TEMP_DIR      = $dir;
my $debug;

my $trim = 0;
my $cfile ='';

if ( -e catfile($localdir,"VD","databases","vrl_*amb")){ unlink catfile($localdir,"VD","databases","vrl_*amb")};
if ( -e catfile($localdir,"VD","databases","vrl_*ann")){ unlink catfile($localdir,"VD","databases","vrl_*ann")};
if ( -e catfile($localdir,"VD","databases","vrl_*pac")){ unlink catfile($localdir,"VD","databases","vrl_*pac")};

### Checking

# Getting fastq files
opendir(DIR, $dir) or die $!;

my @files 
    = grep { 
        /\.fastq$|\.fq$/             # Begins with a period
    && -f "$dir/$_"   # and is a file
} readdir(DIR);

if (scalar @files < 1) { print "Couldn't find valid FastQ files.\n"; die $!; };

# Check 
if ($controlfile ne 'NA'){
	if ( !grep( /^$controlfile$/, @files ) ) {
		print "Control file name not provided or incorrect.\n";
	} 
}

### Save options in a file.
open my $writef, '>>', catfile($dir,"running_options.txt") or warn "couldn't open: $!";
my $datestring = localtime();
my $logoptions = "Options for running VDW (v0.93):\n" .
	"========================\n" .
	"Results are in folder: " . $dir  . "\n" .
	"Files: ". join(",",@files) . "\n" .
	"Spike in sequences: " . $spike  . "\n" .
	"Adaptor for trimming: " . $adaptor . "\n" .
	"Minimun length: " . $length . "\n" .
	"Maximun length: " . $max_length . "\n" .
	"Database: " . $database            . "\n" .
	"Host reference: ".  $host    . "\n" .
	"Control sequence file: " . $controlseq  . "\n" .
	"Control sample file name: " . $controlfile  . "\n" .
	"Standard deviation times: " . $controlconst  . "\n" .
	"Run de-duplication: " . $rmdup  . "\n" .
	"Additional parameters: " . $add_parameters . "\n" .
	"Number of cores: " . $cores  . "\n\n".
	"Start: ". $datestring . "\n" ;
	
print $writef $logoptions;


### Adding path to files
my $stringFile = join " $dir\\", @files; 

### De-duplicate
if($rmdup ne 'NA'){
	foreach my $file1 (@files) {
		my $file = catfile($dir,$file1);
		my $file_tmp = catfile($dir,$file1."tmp.fastq");
		if ( -e -s $file ){
			system("copy ". $file ." ". $file_tmp) == 0
				or warn "Error moving folder";
		}
		if ( -e -s $file_tmp ){
			my $spkdir = catfile($localdir,'VD','bin','seqkit.exe ');
			my $commspk = $spkdir .'rmdup '. $file_tmp .' -s -o ' . $file;
			system($commspk) == 0
				or warn "Error: $commspk . $?";
		}
	}
}
	
### Trimming
if($adaptor ne 'NA' && $length ne 'NA'){
	my $commtrim;
	my $trimdir = 'perl ' . catfile($localdir,'VD','tools','sRNA_clean','sRNA_clean.pl ');
	if($max_length ne 'NA'){
		$commtrim = $trimdir .'-s '. $adaptor . ' -l ' . $length . ' -m ' . $max_length . ' '. $dir.'\\' . $stringFile ;
	} else {
		$commtrim = $trimdir .'-s '. $adaptor . ' -l ' . $length . ' '. $dir.'\\' . $stringFile ;
	}
	system($commtrim) == 0
		 or die "Error: $commtrim . $?";
}

my @array_files;
#Loop through the array printing out the filenames
foreach my $file1 (@files) {
	my $file = catfile($dir,$file1);
    $trim = 0;

    ### FastQC
    my $fqcdir = catfile($localdir,'VD', 'bin','fastQC');
    # my $commfqc = "java -Xmx250m -classpath " . $fqcdir . ";" . catfile($fqcdir,"sam-1.103.jar") . ";" . catfile($fqcdir,"jbzip2-0.9.jar") . " uk.ac.babraham.FastQC.FastQCApplication " . $file . " 2>NULL";
	
    # system($commfqc) == 0
    #     or warn "Error: $commfqc . $?";

    ### Trimming
    if($adaptor ne 'NA' && $length ne 'NA'){
	    my $temp = $file;
	    $temp =~ s/\.fq$/\.clean\.fq/;
	    $temp =~ s/\.fastq$/\.clean\.fq/;
	    if (! -e -s $temp){
	     	$trim = 0;
	 	} else {
			$trim = 1;
		}
    }

    if($trim == 1){
	     $file =~ s/\.fq$/\.clean\.fq/;
	     $file =~ s/\.fastq$/\.clean\.fq/;
	     $file1 =~ s/\.fq$/\.clean\.fq/;
	     $file1 =~ s/\.fastq$/\.clean\.fq/;	 
	        
	     my $commfqc1 = "java -Xmx250m -classpath " . $fqcdir . ";" . catfile($fqcdir,"sam-1.103.jar") . ";" . catfile($fqcdir,"jbzip2-0.9.jar") . " uk.ac.babraham.FastQC.FastQCApplication " . $file  . " 2>NULL";
		
	     system($commfqc1) == 0
	        or warn "Error: $commfqc1 . $?";
    }

    ### run spiking
	if($spike ne 'NA'){
		my $spkdir = catfile($localdir,'VD','bin','seqkit.exe ');
		my $commspk = $spkdir .'locate -p '. $spike . " " . $file .' -o ' . $file .".spike.txt";
		system($commspk) == 0
			or warn "Error: $commspk . $?";

		if (-s "$file.spike.txt"){
			format_spike("$file.spike.txt");
		}
	}

	### Run virus detect 
	my $commvd = "perl " . catfile($localdir,'VD','virus_detect.pl ');
	 $commvd = $database ne 'NA' ?  $commvd . " --reference " . $database . " " : $commvd;
	 if ($database =~ /^l_/){
		my $info = $database. "_genbank.info.gz";
		my $ids = $database . "_idmapping.gz";
		$commvd = $commvd . " --seq_info " . $info . " --prot_tab " . $ids;
	 }
	 $commvd = $host ne 'NA' ? $commvd . " --host_reference " . $host . " ": $commvd;
	 $commvd = $cores ne 'NA' ? $commvd . " --thread_num " . $cores . " ": $commvd;
	 $commvd = $add_parameters ne 'NA' ? $commvd . " " . $add_parameters . " ": $commvd;
	 $commvd = $commvd . " " . $file; 
	 system($commvd) == 0
	  or warn "Error in analysis";
	  
	# move final folder to results
	 my $folderm = catfile($localdir,"results","result_". $file1);
	 if ( -e $folderm ){
		system("move ". $folderm ." ". $dir) == 0
			or warn "Error moving folder";
	 }
	 
	### Control aligment to create statistic 
	my $data_type = Util::detect_DataType($file);
	if ( $controlseq ne 'NA'){ 
		my $control = catfile($localdir,"VD","databases",$controlseq);

		my $align_parameters = $cores ne 'NA' ?  " -t $cores  " : " -t 1 ";
		my $samtools = catfile("$BIN_DIR","samtools"); 

		if ($data_type eq 'mRNA'){
			Util::process_cmd("$align_program index -p $control -a bwtsw $control 2>> $TEMP_DIR/bwa-mem.log", $debug) unless -s "$control.amb";
			Util::process_cmd("$align_program mem $align_parameters $control $file 1> $file.sam 2>> $TEMP_DIR/bwa-mem.log", $debug);
		} else {
	  		align::align_to_reference($align_program, $file, $control, "$file.sam", $align_parameters, 10000, $TEMP_DIR, $debug);
	  	}

		if (-s "$file.sam")
		{
			 Util::process_cmd("$samtools view -@ 5 -bt $control.fai $file.sam > $file.bam 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools sort $file.bam -o $file.sorted.bam 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools mpileup $file.sorted.bam > $file.pileup 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools flagstat $file.sam >$file.stats.txt", $debug);
		
		} 
		my $controout = '';
		$controout = $controout . "File\tControl sequence length\tControl sequence coverage\tDepth\tDepth\tNorm deph kb\t#Reads\t#Mapped reads to control\t%Mapped reads to control\n";
		
		if (-s "$file.pileup" && -s "$control.fai"){	
			my $num=0; my $den=0;
			open my $fh, '<', "$file.pileup" or warn "couldn't open: $!";
			while (<$fh>){
				my @F = split;
				$num=$num+$F[3];
				$den++;
			}
			open my $fh1, '<', "$control.fai" or warn "couldn't open: $!";
			my $size = '';
			while (<$fh1>){
				my @G = split;
				$size=$G[1];
			}
			#0 File name
			$controout = $controout . "$file1\t";
			#1 Control sequence length
			$controout = $controout .  $size;
			#2 Control sequence coverage
			$controout = $controout . "\t". sprintf("%.2f",($den/$size*100)) . "%";
			my $depth=$num/$den;
			#3 Depth
			$controout = $controout . "\t". $depth;
			#4 Depth
			$controout = $controout . "\t". $depth;
			#5 Norm deph kb
			$controout = $controout . "\t". $depth/$size;
		} else {
			#File name
			$controout = $controout . "$file1\t";
			#Control sequence length
			$controout = $controout .  'NA';
			#Control sequence coverage
			$controout = $controout . "\tNA";
			#Depth
			$controout = $controout . "\tNA";
			#Norm deph
			$controout = $controout . "\tNA";
			#Norm deph kb
			$controout = $controout . "\tNA";
		}
		
		if (-s "$file.stats.txt"){
			open my $fh, '<', "$file.stats.txt" or warn "couldn't open: $!";
			while (my $line = <$fh>){
				if(index $line, 'total (QC', >=0){
					$line =~ m/(\d+ )/;
					##Reads
					$controout = $controout . "\t" . $1;
				}
				if(index $line, 'mapped (', >=0){
					$line =~ m/(\d+ )/;
					##Mapped reads to control
					$controout = $controout . "\t".$1;
				}
				if(index $line, 'mapped (', >=0){
					$line =~ m/(\d+.\d+\%)/;
					#%Mapped reads to control
					$controout = $controout . "\t".$1. "\n";
				}
				
			}
		}
		if ($controout ne ""){
		
			my $cresult = "$dir\\control.tsv";
			open (my $fh2, '>>', $cresult) or warn "could not open file";
			print $fh2 $controout;
			close $fh2;
		}
		
		#check if files exists and delete it
		if ( -e "$file.sam"){ unlink "$file.sam"};
		if ( -e "$file.bam"){ unlink "$file.bam"};
		if ( -e "$file.sorted.bam"){ unlink "$file.sorted.bam"};
		#if ( -e "$file.stats.txt"){ unlink "$file.stats.txt"};
		if ( -e "$file.pileup"){ unlink "$file.pileup"};
		if ( -e catfile("$TEMP_DIR","bwa.log")){ unlink catfile("$TEMP_DIR","bwa.log")};
		if ( -e catfile("$TEMP_DIR","samtools.log")){ unlink catfile("$TEMP_DIR","samtools.log")};
		if ( -e catfile("$TEMP_DIR","bwa.sai")){ unlink catfile("$TEMP_DIR","bwa.sai")};

	}
	
	# Delete temp folders
	if (-e catfile($localdir,$file1."_temp")){
		rmtree(catfile($localdir,$file1."_temp")) or warn "couldn't: $!";
	}
	push @array_files , $file;
}

# Write file
my $datestringend = localtime();
print $writef "End: $datestringend \n" ;

# Get spiking
if($spike ne 'NA'){
	merge_spike_files($dir);
}

# Print
print_summary($dir,"report_sRNA_trim.txt","control.tsv","spikeSummary.txt", "sRNA_length.txt",$spike,$controlfile, @array_files);

if ($spike ne 'NA') {
	graph_spiking_sum($dir,$spike);
}

my $control_cutoff;
my $av;
my $sd;
if ($controlfile ne 'NA' && $controlseq ne 'NA'){
	my $sum_file = catfile($dir ,'Summary.tsv');
	$controlconst = $controlconst ne 'NA' ? $controlconst : 2;
	($control_cutoff,$av,$sd) = get_control_cutoff($sum_file,$controlconst,$controlfile);
}

graph_size($dir);
graph_cumulative_clean_sum($dir);
create_html($dir,$spike,\@array_files,$control_cutoff,$av,$sd,$controlconst);

# # Delete partial results
foreach my $file ( glob catfile($dir,'*') ) {
	# if ($file =~ "spikeSum\.txt") {unlink $file;}
	# if ($file =~ "\.spike\.txt") {unlink $file;}
	# if ($file =~ "control\.tsv") {unlink $file;}
	# if ($file =~ "spikeSummary\.txt") {unlink $file;}
	 if (! -d $file  && ($file =~ /\.fastq$/ || $file =~ /\.fq$/ ) ) {unlink $file;}	
}

closedir(DIR); 


sub format_spike {
	my %count;
	my $file = shift or die "Usage: $0 FILE\n";
	open my $fh, '<', $file or die "Could not open '$file' $!";
	while (my $line = <$fh>) {
	    chomp $line;
	    my @str = split /\s+/, $line;
	        $count{$str[2]}++;
	}
	
	my $spikef ='';
	my $name = $file;
	$name =~ s/\.spike\.txt//;

	open my $fh1, '>', "$name.spikeSum.txt" or warn "couldn't open: $!";

	foreach my $str (sort keys %count) {
	    $spikef = $spikef . basename($name) ."\t".$str."\t".($count{$str}) . "\n"; 
	}
	print $fh1 $spikef;

}

sub print_summary {
	my $dir = shift;
	my $trim = catfile($dir,shift);
	my $control = catfile($dir,shift);
	my $spikeFile = catfile($dir,shift);
	my $sRNA = catfile($dir,shift);
	my $spike = shift;
	my $controlfile = shift;
	my @array_files = @_;
	my @spikes = split /,/, $spike;

	opendir(DIR, $dir) or die $!;

	#Get trimmed data
	my %dataFile;
	
	if (-e -s $trim){
		open FILE1, "$trim" or warn;
	
		while (my $line1=<FILE1>) {   
			# chomp;
			my @field = split /\t/, $line1;  
			   if (length(trim($field[0])) > 0){
				$dataFile{trim($field[0])}{raw}   = trim($field[1]);  
				$dataFile{trim($field[0])}{clean}   = trim($field[8]);
				$field[0] =~ s/.fastq//;
				$field[0] =~ s/.fq//;
				$dataFile{trim($field[0].".clean.fq")}{raw}   = trim($field[1]);  
				$dataFile{trim($field[0].".clean.fq")}{clean}   = trim($field[8]);
			}
		}
	}

	#Get control results
	my %dataFile1;

	if (-e -s $control){
	
		open FILE2, "$control" or warn;
		while (my $line1=<FILE2>) {   
			# chomp;
			my @field = split /\t/, $line1;
			   if (length(trim($field[0])) > 0){
			   	#Control sequence coverage
				$dataFile1{trim($field[0])}{concov}   = trim($field[2]); 
				#Norm deph
				$dataFile1{trim($field[0])}{depth}   = trim($field[4]);  
				#Norm deph kb
				$dataFile1{trim($field[0])}{kb}   = trim($field[5]);
				##Mapped reads to control
				$dataFile1{trim($field[0])}{map}   = trim($field[7]);
				#%Mapped reads to control
				$dataFile1{trim($field[0])}{permap}   = trim($field[8]);
				##Raw reads
				$dataFile1{trim($field[0])}{raw}   = trim($field[6]);
			}
		}
	}

	#Get spike in results
	my %dataFile2;

	if (-e -s $spikeFile){
		open FILE3, "$spikeFile" or warn;
		while (my $line1=<FILE3>) {   
			# chomp;
			my @field = split /\t/, $line1;

			if (length(trim($field[0])) > 0){
				$dataFile2{trim($field[0])}{$field[1]} = trim($field[2]); 
			}
		}
	}

	#Get sRNA results
	my %dataFile3;
	
	if (-e -s $sRNA){
		
		open FILE4, "$sRNA" or warn;
		my $sizes = <FILE4>; 
		my @listFq = split /\t/, $sizes;
		
		while (my $line1=<FILE4>) {   
			# chomp;
			my @field = split /\t/, $line1;
			my $i = 0;
			foreach my $column (@field) {

				if (length(trim($column)) > 0){
					$dataFile3{trim($listFq[$i]).".fq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".clean.fq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".clean.fastq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".fastq"}{$field[0]} = trim($column); 
				}
				$i++;
			}
		}
	}

	### Run summary
	## Header
	open my $fh1, '>', catfile($dir,"Summary.tsv") or warn "couldn't open: $!";
	my $out = "File\t#Raw reads\t#clean reads\t21\t22\t23\t24\t";
	foreach my $spk (@spikes) {
		$out = $out . "Norm. Spike: ". $spk. "\t"."# Spikes: ". $spk. "\t";
	}
	$out = $out ."Control coverage\tNormalized control depth\tNormalized depth/kb control coverage\t#Mapped to control\t%Mapped to control\n";
	
	## Body
	foreach my $file (@array_files) { 
		my $clean =1;
		if($dataFile1{$file}{raw}){
			$clean = $dataFile1{$file}{raw};
		}

		$file = basename($file);
		if ($controlfile ne 'NA' && $controlfile eq $file){
			$out = $out . "Control: ". $file."\t";
		} else{
			$out = $out . $file."\t";
		}
		
		# raw and clean
		if($dataFile{$file}{raw}){ 
			$out = $out . $dataFile{$file}{raw}."\t".$dataFile{$file}{clean}."\t";
			$clean = $dataFile{$file}{clean};
			if ($clean == 0) { $clean = $dataFile1{$file}{raw} };
		} else{
			$out = $out . "NA\tNA\t";
		}

		#21-24
		foreach (21..24){
			if($dataFile3{$file}{$_}){ 
				$out = $out . $dataFile3{$file}{$_}."\t";
			} else{
				$out = $out . "NA\t";
			}
		}

		#spikes
		foreach my $spk (@spikes) {
			if($dataFile2{$file}{$spk}){
				$out = $out . ($dataFile2{$file}{$spk}/$clean*1000000) . "\t" . ($dataFile2{$file}{$spk}) ."\t";
			} else {
				$out = $out . "NA\tNA\t";
			}
		}

		#control
		if($dataFile1{$file}{concov}){ 
			#Control sequence coverage,Norm deph,Norm deph kb,#Mapped reads to control,%Mapped reads to control
			my $normDeph = 'NA';
			if($dataFile1{$file}{depth} ne 'NA') { $normDeph = sprintf("%.2f", ($dataFile1{$file}{depth}/$clean*1000000)); }
			my $normDephKb = 'NA';
			if($dataFile1{$file}{kb} ne 'NA') { $normDeph = sprintf("%.6f", $dataFile1{$file}{kb}*1000); }

			$out = $out . $dataFile1{$file}{concov}."\t". $normDeph ."\t". $normDephKb . "\t". $dataFile1{$file}{map}. "\t". $dataFile1{$file}{permap}."\t";
		} else {
			$out = $out . "NA\tNA\tNA\tNA\tNA\t";
		}

		$out = $out ."\n";
	}

	print $fh1 $out;
}

sub merge_spike_files{
	my $dir = shift;
	opendir(DIR, $dir) or die $!;
	
	open my $fh, '>', catfile($dir,"spikeSummary.txt") or warn "couldn't open: $!";
	
	my @files = grep(/spikeSum\.txt$/,readdir(DIR));
	
	foreach my $file (@files) {
		open FILE3, catfile($dir,$file) or  warn "couldn't open file";
		while (<FILE3>) {  print $fh $_; }
		close FILE3;
	}
	#closedir(DIR);
}

sub get_control_cutoff{
	my $sum_file = shift;
	my $const = shift;
	my $control_file = shift;
	
	my $control_col;
	my $perc_control = 0;
	my @control_percent = ();
	
	open(FILE,$sum_file) || die "WRONG FILE";
	while(my $line = <FILE>){
		chomp $line;
		next if $line =~ /^\s*$/;
		my @line = split(/\t/,$line);
		if ($line =~ /^File/){
			$control_col = first_index { $_ eq '%Mapped to control' } @line;
			next;
		}
		next if $line[$control_col] eq 'NA';
		
		$line[$control_col] =~ s/%//g;
		$line[0] =~ s/Control:\ //g;
		$line[0] =~ s/\.fastq//g;
		$line[0] =~ s/\.clean.fq//g;
		$control_file =~ s/\.fastq//g;
		$control_file =~ s/\.clean.fq//g;
		
		if( $line[0] eq $control_file ){ 
			$perc_control = $line[$control_col]; 
			$perc_control =~ s/%//g;
			next; 
		} 
		push @control_percent, $line[$control_col];
	}
	my $av = 0;
	my $std = 0;
	if (@control_percent && $perc_control >0 ){
		$av = average(\@control_percent)/$perc_control;
		$std = stdev(\@control_percent)/$perc_control;
	}
	
	my $cutoff = $av + ($std * $const);
	return ($cutoff,$av,$std);
}
