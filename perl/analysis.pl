#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use File::Spec::Functions 'catfile';
use File::Path;
use Cwd qw(getcwd);
use lib catfile("VD","bin");
use Util;
use align;

my $localdir = getcwd;

my $dir = $ARGV[0]; # 'plant';
my $spike = $ARGV[1]; #'U95';
my $adaptor = $ARGV[2]; #'v229';
my $length  = $ARGV[3];
my $database = $ARGV[4];
my $host  = $ARGV[5];
my $cores = $ARGV[6];
my $controlseq = $ARGV[7];
my $add_parameters = $ARGV[8]; 

my $BIN_DIR  = catfile("VD","bin"); 
my $align_program    = catfile("$BIN_DIR","bwa");
my $TEMP_DIR      = $dir;
my $debug;

my $trim = 0;
my $cfile ='';

if ( -e catfile($localdir,"VD","databases","vrl_*amb")){ unlink catfile($localdir,"VD","databases","vrl_*amb")};
if ( -e catfile($localdir,"VD","databases","vrl_*ann")){ unlink catfile($localdir,"VD","databases","vrl_*ann")};
if ( -e catfile($localdir,"VD","databases","vrl_*pac")){ unlink catfile($localdir,"VD","databases","vrl_*pac")};


opendir(DIR, $dir) or die $!;

my @files 
    = grep { 
        /\.fastq$|\.fq$/             # Begins with a period
    && -f "$dir/$_"   # and is a file
} readdir(DIR);

my $stringFile = join " $dir\\", @files; 

### Trimming
if($adaptor ne 'NA' && $length ne 'NA'){
	my $trimdir = 'perl ' . catfile($localdir,'VD','tools','sRNA_clean','sRNA_clean.pl ');
	my $commtrim = $trimdir .'-s '. $adaptor . ' -l ' . $length . ' '. $dir.'\\' . $stringFile ;
	system($commtrim) == 0
		 or die "Error: $commtrim . $?";
}

# Loop through the array printing out the filenames
foreach my $file1 (@files) {
	my $file = catfile($dir,$file1);
    $trim = 0;

    ### FastQC
    my $fqcdir = catfile($localdir,'VD', 'bin','fastQC');
    my $commfqc = "java -Xmx250m -classpath " . $fqcdir . ";" . catfile($fqcdir,"sam-1.103.jar") . ";" . catfile($fqcdir,"jbzip2-0.9.jar") . " uk.ac.babraham.FastQC.FastQCApplication " . $file . " 2>NULL";
	
    system($commfqc) == 0
        or warn "Error: $commfqc . $?";

    ### Trimming
    if($adaptor ne 'NA' && $length ne 'NA'){
	    my $temp = $file;
	    $temp =~ s/\.fq$/\.clean\.fq/;
	    $temp =~ s/\.fastq$/\.clean\.fq/;
	    if (!-s $temp){
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
	}

	### Run virus detect 
	# my $commvd = "perl " . catfile($localdir,'VD','virus_detect.pl ');
	 # $commvd = $database ne 'NA' ?  $commvd . " --reference " . $database . " " : $commvd;
	 # if ($database =~ /^l_/){
		# my $info = $database. "_genbank_info.gz";
		# my $ids = $database . "_idmapping.gz";
		# $commvd = $commvd . " --seq_info " . $info . " --prot_tab " . $ids;
	 # }
	 # $commvd = $host ne 'NA' ? $commvd . " --host_reference " . $host . " ": $commvd;
	 # $commvd = $cores ne 'NA' ? $commvd . " --thread_num " . $cores . " ": $commvd;
	 # $commvd = $add_parameters ne 'NA' ? $commvd . " " . $add_parameters . " ": $commvd;
	 # $commvd = $commvd . " " . $file; 
	 # system($commvd) == 0
	  # or die next;
	  
	### move final folder to results
	 my $folderm = catfile($localdir,"results","result_". $file1);
	 if ( -e $folderm ){
		system("move ". $folderm ." ". $dir) == 0
			or warn "Error moving folder";
	 }
	 
	 
	 ### Control aligment to create statistic
	if ( $controlseq ne 'NA'){
	  my $control = catfile($localdir,"VD","databases",$controlseq);

	  my $align_parameters = $cores ne 'NA' ?  " -t $cores  " : " -t 1 ";
	  my $samtools = catfile("$BIN_DIR","samtools"); 

	  align::align_to_reference($align_program, $file, $control, "$file.sam", $align_parameters, 10000, $TEMP_DIR, $debug);

		if (-s "$file.sam")
		{
			 Util::process_cmd("$samtools view -@ 5 -bt $control.fai $file.sam > $file.bam 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools sort $file.bam -o $file.sorted.bam 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools mpileup $file.sorted.bam > $file.pileup 2> $TEMP_DIR/samtools.log", $debug);
			 Util::process_cmd("$samtools flagstat $file.sam >$file.stats.txt", $debug);
		
		} 
		my $controout = '';
		#$controout = $controout . "Control sequence length\tControl sequence coverage\tDepth\tMapped reads\n";
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
			$controout = $controout . "Control sequence length: ". $size;
			$controout = $controout . "\tControl sequence coverage: ". sprintf("%.2f",($den/$size*100)) . "%";
			my $depth=$num/$den;
			$controout = $controout . "\tDepth: ". sprintf("%.2f",$depth);
		}
		
		if (-s "$file.stats.txt"){
			open my $fh, '<', "$file.stats.txt" or warn "couldn't open: $!";
			while (my $line = <$fh>){
				if(index $line, 'mapped (', >=0){
					$line =~ m/(\d+.\d+\%)/; 
					$controout = $controout . "\tMapped reads: ".$1;
				}
			}
		}
		if ($controout ne ""){
			my $cresult = "$dir\\control.1html";
			open (my $fh2, '>>', $cresult) or warn "could not open file";
			print $fh2 "$file1\t$controout";
			close $fh2;
		}
		
		if ( -e "$file.sam"){ unlink "$file.sam"};
		if ( -e "$file.bam"){ unlink "$file.bam"};
		if ( -e "$file.sorted.bam"){ unlink "$file.sorted.bam"};
		#if ( -e "$file.stats.txt"){ unlink "$file.stats.txt"};
		if ( -e "$file.pileup"){ unlink "$file.pileup"};
		if ( -e catfile("$TEMP_DIR","bwa.log")){ unlink catfile("$TEMP_DIR","bwa.log")};
		if ( -e catfile("$TEMP_DIR","samtools.log")){ unlink catfile("$TEMP_DIR","samtools.log")};
		if ( -e catfile("$TEMP_DIR","bwa.sai")){ unlink catfile("$TEMP_DIR","bwa.sai")};

	}
	if (-e catfile($localdir,$file1."_temp")){
		rmtree(catfile($localdir,$file1."_temp")) or warn "couldn't: $!";
	}
  

}
closedir(DIR); 

