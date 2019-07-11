use strict;
use warnings;
 
# my %count;
# my $file = shift or die "Usage: $0 FILE\n";
# open my $fh, '<', $file or die "Could not open '$file' $!";
# while (my $line = <$fh>) {
#     chomp $line;
#     my @str = split /\s+/, $line;
#         $count{$str[2]}++;

# }
# my $name = $file;
# $name =~ s/\.spike\.txt//;
# foreach my $str (sort keys %count) {
#     printf "%s\t%s\t%s\n", $name, $str, $count{$str};
# }

use Data::Dumper;
my $trim = $ARGV[0];
my $control = $ARGV[1];
my $spikeFile = $ARGV[2];
my $sRNA = $ARGV[3];
my $dir = '/Users/mirellaflores/Documents/mrf252/projects/VD/test/results/';
my $spike = 'ATGGAGCCAGTTC,ATGCGG,ACTGG,AGCACTCTGGGAT,ATGCTGGACCATG,AAGCCTGCGTATG,GAGCGTCCGATAT,CCGGGATCGTTAA,CGATATGCCTGGACGT';
my @spikes = split /,/, $spike;

opendir(DIR, $dir) or die $!;

my @files 
    = grep { 
        /\.fastq$|\.fq$/             # Begins with a period
    && -f "$dir/$_"   # and is a file
} readdir(DIR);



open FILE1, "$trim" or die;
my %dataFile;

while (my $line1=<FILE1>) {   
    # chomp;
    my @field = split /\t/, $line1;  
	   if (length(trim($field[0])) > 0){
	   	$dataFile{trim($field[0])}{raw}   = trim($field[1]);  
		$dataFile{trim($field[0])}{clean}   = trim($field[7]);
	}
}


open FILE2, "$control" or die;
my %dataFile1;

while (my $line1=<FILE2>) {   
    # chomp;
    my @field = split /\t/, $line1;  
	   if (length(trim($field[0])) > 0){
	   	$dataFile1{trim($field[0])}{concov}   = trim($field[2]); 
	   	$dataFile1{trim($field[0])}{seq}   = trim($field[4]); 
	   	$dataFile1{trim($field[0])}{kb}   = trim($field[5]); 
	}
}
#print Dumper(\%dataFile1);

open FILE3, "$spikeFile" or die;
my %dataFile2;

while (my $line1=<FILE3>) {   
    # chomp;
    my @field = split /\t/, $line1;

   	if (length(trim($field[0])) > 0){
   		$dataFile2{trim($field[0])}{$field[1]} = trim($field[2]); 
	}
}

open FILE4, "$sRNA" or die;
my $sizes = <FILE4>; 
my @listFq = split /\t/, $sizes;

my %dataFile3;

while (my $line1=<FILE4>) {   
    # chomp;
    my @field = split /\t/, $line1;
    my $i = 0;
    foreach my $column (@field) {

	   	if (length(trim($column)) > 0){
	   		$dataFile3{trim($listFq[$i])}{$field[0]} = trim($column); 
		}
		$i++;
	}
}

### Run summary

open my $fh1, '>', "$trim.summary.txt" or warn "couldn't open: $!";
my $out = "File\t#Raw reads\t#clean reads\t21\t22\t23\t24\t";
foreach my $spk (@spikes) {
	$out = $out . "Spike: ". $spk. "\t";
}
$out = $out ."Control coverage\tNormalized control deph\tNormalized depth/kb control coverage\n";
# print Dumper(\%dataFile3);

foreach my $file (@files) { 

	$out = $out . $file."\t";
	
	# raw and clean
	if($dataFile{$file}{raw}){ 
		$out = $out . $dataFile{$file}{raw}."\t".$dataFile{$file}{clean}."\t";
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
			$out = $out .$dataFile2{$file}{$spk}."\t";
		} else {
			$out = $out . "NA\t";
		}
	}

	#control
	if($dataFile1{$file}{concov}){ 
		$out = $out . $dataFile1{$file}{concov}."\t".$dataFile1{$file}{seq}."\t".$dataFile1{$file}{kb}."\t";
	} else {
		$out = $out . "NA\tNA\tNA\t";
	}

	$out = $out ."\n";
}

print $fh1 $out;


#print Dumper(\%dataFile);

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
