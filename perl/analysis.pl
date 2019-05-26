#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use File::Spec::Functions 'catfile';
use Cwd qw(getcwd);

my $localdir = getcwd;

# my $dir = 'C:\git\VD\results\yora'; #$ARGV[0]; # 'plant';
# my $spike = 'ATGGAGCCAGTTC'; #$ARGV[1]; #'U95';
# my $adaptor = 'CAGATCGGAAGAGCACA'; #$ARGV[2]; #'v229';
# my $length  = '15'; #$ARGV[3];
# my $database = 'vrl_Plants_229_U95'; #$ARGV[4];
# my $host  = 'NA'; #$ARGV[5];
# my $cores = 'NA'; #$ARGV[6];

my $dir = $ARGV[0]; # 'plant';
my $spike = $ARGV[1]; #'U95';
my $adaptor = $ARGV[2]; #'v229';
my $length  = $ARGV[3];
my $database = $ARGV[4];
my $host  = $ARGV[5];
my $cores = $ARGV[6];
my $param = $ARGV[7];

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

# Loop through the array printing out the filenames
foreach my $file1 (@files) {
	my $file = catfile($dir,$file1);
    $trim = 0;
    my $fqcdir = catfile($localdir,'VD', 'bin','fastQC');
    my $commfqc = "java -Xmx250m -classpath " . $fqcdir . ";" . catfile($fqcdir,"sam-1.103.jar") . ";" . catfile($fqcdir,"jbzip2-0.9.jar") . " uk.ac.babraham.FastQC.FastQCApplication " . $file;
	
    system($commfqc) == 0
        or die "Error: $commfqc . $?";

    if($adaptor ne 'NA' && $length ne 'NA'){
     my $trimdir = 'perl ' . catfile($localdir,'VD','tools','sRNA_clean','sRNA_clean.pl ');
     my $commtrim = $trimdir .'-s '. $adaptor . ' -l ' . $length . ' ' . $file;
     system($commtrim) == 0
         or die "Error: $commtrim . $?";
     $trim = 1;
    } 

    if($trim == 1){
     $file =~ s/\.fq$/\.clean\.fq/;
     $file =~ s/\.fastq$/\.clean\.fq/;
     $file1 =~ s/\.fq$/\.clean\.fq/;
     $file1 =~ s/\.fastq$/\.clean\.fq/;	 
    } 

	if($spike ne 'NA'){
	 my $spkdir = catfile($localdir,'VD','bin','seqkit.exe ');
	 my $commspk = $spkdir .'locate -p '. $spike . " " . $file .' -o ' . $file .".spike.txt";
	 system($commspk) == 0
		  or die "Error: $commspk . $?";
	}
	my $commvd = "perl " . catfile($localdir,'VD','virus_detect.pl ');
	 $commvd = $database ne 'NA' ?  $commvd . " --reference " . $database . " " : $commvd;
	 if ($database =~ /^l_/){
		my $info = $database. "_genbank_info.gz";
		my $ids = $database . "_idmapping.gz";
		$commvd = $commvd . " --seq_info " . $info . " --prot_tab " . $ids;
	 }
	 $commvd = $host ne 'NA' ? $commvd . " --host_reference " . $host . " ": $commvd;
	 $commvd = $cores ne 'NA' ? $commvd . " --thread_num " . $cores . " ": $commvd;
	 $commvd = $commvd . " " . $file; 
	 system($commvd) == 0
	  or die next;
	  
	 my $folderm = catfile($localdir,"results","result_". $file1);
	 if ( -e $folderm ){ 
		system("move ". $folderm ." ". $dir) == 0
			or die next;
	 };
}

closedir(DIR); 
print $ARGV[0];

