use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Spec::Functions 'catfile';
use List::Util qw(reduce);

# concat_blast("test1","adapt_180905_SNK268_A_L002_AMRW-22-10_R1.clean.fq","spike_190517_SNK268_B_L003_AMRW-37-7_R1.clean.fq","control_190206_SNK268_A_L004_AMRW-32-48_R1.clean.fq"); 	

# print_summary("test1","report_sRNA_trim.txt","NA","spikeSummary.txt", "sRNA_length.txt","AATGC,ATGAA,TGCCC,pattern","NA", undef, "adapt_180905_SNK268_A_L002_AMRW-22-10_R1.clean.fq","spike_190517_SNK268_B_L003_AMRW-37-7_R1.clean.fq","control_190206_SNK268_A_L004_AMRW-32-48_R1.clean.fq"); 	

sub concat_blast {
	my $dir = shift;
	my @array_files = @_;

	foreach my $sample (@array_files) {

		my @sources;
		push @sources, catfile($dir ,"result_$sample" , "blastn.tab");
		push @sources, catfile($dir ,"result_$sample" , "blastx.tab");

		open my $out, '>', catfile($dir ,"result_$sample" , "blastxn.tab") or warn "Could not open blastxn for appending\n";
		close $out;
		open $out, '>>', catfile($dir ,"result_$sample" , "blastxn.tab") or warn "Could not open blastxn for appending\n"; 

		foreach my $file (@sources) {
		    if (open my $in, '<', $file) {
		        while (my $line = <$in>) {
		            print $out $line;
		        }
		        close $in;
		    }
		}
		close $out;
		}
}

sub print_summary {
	my $dir = shift;
	my $trim = catfile($dir,shift);
	my $control = catfile($dir,shift);
	my $spikeFile = catfile($dir,shift);
	my $sRNA = catfile($dir,shift);
	my $spike = shift;
	my $controlfile = shift;
	my $fileBlast = shift;
	my @array_files = @_;
	my @spikes = split /,/, $spike;
	my $extended_table = 0;

	# opendir(DIR, $dir) or die $!;

	#Get trimmed data
	my %dataFile;
	my %results;
	
	if (-e -s $trim){
		open FILE1, "$trim" or warn;
	
		while (my $line1=<FILE1>) {
			# chomp;
			next if($line1 =~ /^#sRNA/);
			my @field = split /\t/, $line1;
		
			if (length(trim($field[0])) > 0){
				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;

				$dataFile{trim($field[0])}{raw}   = trim($field[1]);  
				$dataFile{trim($field[0])}{clean}   = trim($field[8]);
				$field[0] =~ s/.fastq//;
				$field[0] =~ s/.fq//;
				$dataFile{trim($field[0].".clean.fq")}{raw}   = trim($field[1]);  
				$dataFile{trim($field[0].".clean.fq")}{clean}   = trim($field[8]);
				$results{$sample}{"trimming"}{raw}   = trim($field[1]);  
				$results{$sample}{"trimming"}{clean}   = trim($field[8]);
			}
		}
	}

	#Get sRNA results to get size 21-24
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
					my $sample = trim($listFq[$i]);
					$sample =~ s/\.clean\.fastq$//g;
					$sample =~ s/\.clean\.fq$//g;
					$sample =~ s/\.clean$//g;
					$sample =~ s/\.fastq$//g;
					$sample =~ s/\.fq$//g;

					$dataFile3{trim($listFq[$i]).".fq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".clean.fq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".clean.fastq"}{$field[0]} = trim($column); 
					$dataFile3{trim($listFq[$i]).".fastq"}{$field[0]} = trim($column);
					
					if (($field[0]+0 >20) && ($field[0]+0 <25)){
						$results{$sample}{"sRNA"}{$field[0]} = trim($column); 
						$results{$sample}{"sRNA"}{'sum21-24'} += trim($column);
					}
					if($results{$sample}{"trimming"}{clean} && $results{$sample}{"sRNA"}{'sum21-24'} && $results{$sample}{"trimming"}{clean} >0 ){
						$results{$sample}{"sRNA"}{'sumClean'} = $results{$sample}{"sRNA"}{'sum21-24'}/$results{$sample}{"trimming"}{clean};
					} else {
						$results{$sample}{"sRNA"}{'sumClean'} = 'NA';
					}
				}
				$i++;
			}
		}
	}


	#Get control results
	my %dataFile1;
	my $controlSample = "control_190206_SNK268_A_L004_AMRW-32-48_R1.clean.fq";
	my $contaminRateControl = 'NA';
	$control = "test1/control.tsv";

	if (-e -s $control){
	
		open FILE2, "$control" or warn;
		while (my $line=<FILE2>) {
			# chomp;
			next if($line =~ /^File/); 
			my @field = split /\t/, $line;
			if (length(trim($field[0])) > 0 && trim($field[0]) eq $controlSample){
				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;
				my $sum = $results{$sample}{"sRNA"}{'sum21-24'};
				if ($sum > 0 ) {
					$contaminRateControl   = trim($field[7])/$results{$sample}{"sRNA"}{'sum21-24'} ;
				}
			}
		}
		open FILE, "$control" or warn;

		while (my $line1=<FILE>) {
			next if($line1 =~ /^File/);
			my @field = split /\t/, $line1;
			if (length(trim($field[0])) > 0){
			   	#Control sequence coverage
				$dataFile1{trim($field[0])}{concov}   = trim($field[2]); 
				#Norm deph
				$dataFile1{trim($field[0])}{depth}   = trim($field[4]);  
				#Norm deph kb
				$dataFile1{trim($field[0])}{kb}   = trim($field[5]);
				##Mapped reads to control
				$dataFile1{trim($field[0])}{numMapControl}   = trim($field[7]);
				#%Mapped reads to control
				$dataFile1{trim($field[0])}{permap}   = trim($field[8]);
				##Raw reads
				$dataFile1{trim($field[0])}{controlRaw}   = trim($field[6]);

				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;
				#Control sequence coverage
				$results{$sample}{"control"}{concov}   = trim($field[2]); 
				#Norm deph
				$results{$sample}{"control"}{depth}   = trim($field[4]);  
				#Norm deph kb
				$results{$sample}{"control"}{kb}   = trim($field[5]);
				##Mapped reads to control
				$results{$sample}{"control"}{numMapControl}   = trim($field[7]); 
				#%Mapped reads to control
				$results{$sample}{"control"}{permap}   = trim($field[8]);
				##Raw reads
				$results{$sample}{"control"}{raw}   = trim($field[6]);
				#%Mapped reads (21-24nts) to control
				my $sum = $results{$sample}{"sRNA"}{'sum21-24'};
				my $per2124MapControl = 'NA';
				if ($sum > 0 ) {
					$per2124MapControl   = trim($field[7])/$results{$sample}{"sRNA"}{'sum21-24'} ;
				}
				$results{$sample}{"control"}{per2124MapControl} = $per2124MapControl;
				if ($contaminRateControl ne 'NA' && $per2124MapControl ne 'NA') {
					$results{$sample}{"control"}{contaminRate}   = $per2124MapControl/$contaminRateControl;
				} else {
					$results{$sample}{"control"}{contaminRate}   = 'NA';
				}
			}
		}
	}
# print Dumper \%results;
	#Get spike in results
	my %dataFile2;
	# my @spikeListRaw;

	if (-e -s $spikeFile){
		open FILE3, "$spikeFile" or warn;
		while (my $line1=<FILE3>) {   
			# chomp;
			next if($line1 =~ /pattern/);
			my @field = split /\t/, $line1;

			if (length(trim($field[0])) > 0){
				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;

				$dataFile2{trim($field[0])}{$field[1]} = trim($field[2]);
				$results{$sample}{"spike"}{$field[1]} = trim($field[2]);
				# push @spikeListRaw, $field[1];
			}
		}
	}
	# my @spikeList = uniq(@spikeListRaw);


	#Get blast results
	my %dataFileBlast;

	foreach my $file (@array_files) {
		
		$fileBlast = catfile($dir ,"result_$file" , "blastxn.tab");
		print STDERR $fileBlast ."\n";
		if (-e -s $fileBlast){
			
			open FILE5, "$fileBlast" or warn;
			
			while (my $line1=<FILE5>) {   
				# chomp;
				next if($line1 =~ /^Sample\t/);
				my @field = split /\t/, $line1;
				my $sample = trim($file);
				my $genus = trim($field[12]);

				push @{$dataFileBlast{$sample}{$genus}}, {
					'description' =>trim($field[13]),
					'reference' =>trim($field[2]),
					'genus' => $genus,
					'type' => trim($field[1]), #blast
					'lenCoverage' => trim($field[4]),
					'perCoverage' => trim($field[5]),
					'depth' => trim($field[7]),
					'depthNor' => trim($field[8]),
					'iden' => trim($field[9]),
					'idenMax' => trim($field[10]),
					'idenMin' => trim($field[11]),
					'depthFormLen' => trim($field[8]) * trim($field[5])/100 * trim($field[4]),  #depthNor * (perCoverage/100) * lenCoverage
					'depthForm' => trim($field[8]) * trim($field[5])/100, #depthNor * (perCoverage/100) * len
				}
			}
		}
	}
	my %dataFileBlastFiltered = get_max_by_genus('depthFormLen', %dataFileBlast);

	while (my ($sample, $genuses) = each %dataFileBlastFiltered) {
		$sample =~ s/\.clean\.fastq$//g;
		$sample =~ s/\.clean\.fq$//g;
		$sample =~ s/\.clean$//g;
		$sample =~ s/\.fastq$//g;
		$sample =~ s/\.fq$//g;
		while (my ($genus, $entries) = each %$genuses) {  
    		push @{$results{$sample}{"blast"}}, $entries;
    	}
    }

    #add coverageCutoff according to virus. This is done in a second round since it uses previous results
	my ($cutoff) = get_samples_stats(%results);
	if($cutoff){
		my %virusCutoff = get_virus_summary("control",$cutoff,%dataFileBlastFiltered);

		while (my ($sample, $resultType) = each %results) {

	    	while (my ($type, $arrayEntries) = each %$resultType) {
	    		next if($type ne 'blast');

	    		for my $i (0 .. scalar @{$arrayEntries}) {  
	    			if(@{$arrayEntries}[$i]){
		    			my $virusName = lc @{$arrayEntries}[$i]->{description};
		    			$virusName =~ s/\.$//g;
		    			if($virusCutoff{$virusName}){
		    				$results{$sample}{'blast'}[$i]{coverageCutoff} = $virusCutoff{$virusName}{coverageCutoff};
		    			}
		    		}
	    		}
	    	}
	    }
	}
# print "\n\n\n\n\n\n" .Dumper \%results;

	print_summaryR("varibalesfile", \@spikes,\@array_files, %results);

	### Run summary
	## Header
	open my $fh1, '>', catfile($dir,"SummaryT.tsv") or warn "couldn't open: $!";
	my $out = "";
	my $header = "File\t#Raw reads\t#clean reads\t21\t22\t23\t24\tSum(21-24)\tSum(21-24)/clean\t";
	foreach my $spk (@spikes) {
		$header = $header . "Norm. Spike: ". $spk. "\t"."# Spikes: ". $spk. "\t";
	}
	$header = $header ."Control coverage\tNormalized control depth\tNormalized depth/kb control coverage\t#Mapped to control\t%Mapped to control";
	#extended table
	# if($extended_table == 1){
		$header = $header . "\tReference\t" .
					"sRSA Results(Virus)\t".
					"Viral genus detect\t".
					"BLAST\t".
					"Length sequence covered\t".
					"% sequence covered\t".
					"Depth\t".
					"Depth Normalized\t".
					"%identity\t".
					"%identity Max\t".
					"%identity min\t".
					"# reads mapped\t".
					"% reads mapped\t".
					"Contamination rate\t".
					"Virus specific cutoff\t".
					"Depth (Nor) *(%Coverage/100)*length\t".
					"Depth (Nor) *(%Coverage/100)";
	# }
		
	## Body
	my $outT = "";
	foreach my $file (@array_files) {
		my $clean =1;
		if($dataFile1{$file}{controlRaw}){
			$clean = $dataFile1{$file}{controlRaw};
		}

		$file = basename($file);
		if ($controlfile ne 'NA' && $controlfile eq $file){
			$out = "Control: ". $file."\t";
		} else{
			$out = $file."\t";
		}
		
		# raw and clean
		if($dataFile{$file}{raw}){ 
			$out = $out . $dataFile{$file}{raw}."\t".$dataFile{$file}{clean}."\t";
			$clean = $dataFile{$file}{clean};
			if ($clean == 0) { $clean = $dataFile1{$file}{controlRaw} };
		} else{
			$out = $out . "NA\tNA\t";
		}

		#21-24 and sum + sum/clean
		my $sumReads = 0;
		foreach (21..24){
			if($dataFile3{$file}{$_}){ 
				$out = $out . $dataFile3{$file}{$_}."\t";
				$sumReads += $dataFile3{$file}{$_};
			} else{
				$out = $out . "NA\t";
			}
		}
		$out = $out . $sumReads . "\t";
		if ($clean && $clean > 0) { $out = $out . $sumReads/$clean . "\t"; }
		else { $out = $out . "NA\t"; }

		#spikes
		foreach my $spk (@spikes) {
			if($dataFile2{$file}{$spk} && $clean && $clean != 0){
				$out = $out . ($dataFile2{$file}{$spk}/$clean*1000000) . "\t" . ($dataFile2{$file}{$spk}) ."\t";
			} elsif ($dataFile2{$file}{$spk}){
				$out = $out . "NA\t" . ($dataFile2{$file}{$spk}) ."\t";
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

			$out = $out . $dataFile1{$file}{concov}."\t". $normDeph ."\t". $normDephKb . "\t". $dataFile1{$file}{numMapControl}. "\t". $dataFile1{$file}{permap}."\t";
		} else {
			$out = $out . "NA\tNA\tNA\tNA\tNA\t";
		}
		
		#extended table
		# if($extended_table == 1){
		my $sample = $file;
		if($dataFileBlast{$sample}){
			my $out0 = "\n" . $out;print STDERR Dumper \$out;
			my $outB;
			for  my $reference (keys $dataFileBlast{$sample}){
				# $outB = $out0 . $reference ."\t".
					# $dataFileBlast{$sample}{$reference}{'description'}."\t".
					# $dataFileBlast{$sample}{$reference}{'genus'}."\t".
					# $dataFileBlast{$sample}{$reference}{'type'}."\t".
					# $dataFileBlast{$sample}{$reference}{'lenCoverage'}."\t".
					# $dataFileBlast{$sample}{$reference}{'perCoverage'}."\t".
					# $dataFileBlast{$sample}{$reference}{'depth'}."\t".
					# $dataFileBlast{$sample}{$reference}{'depthNor'}."\t".
					# $dataFileBlast{$sample}{$reference}{'iden'}."\t".
					# $dataFileBlast{$sample}{$reference}{'idenMax'}."\t".
					# $dataFileBlast{$sample}{$reference}{'idenMin'}."\n";
					# $dataFileBlast{$sample}{$reference}{'nroMapped'}."\t".
					# $dataFileBlast{$sample}{$reference}{'perMapped'}."\t".
					# $dataFileBlast{$sample}{$reference}{'contaminRate'}."\t".
					# $dataFileBlast{$sample}{$reference}{'virusCutoff'}."\t".
					# $dataFileBlast{$sample}{$reference}{'depthFormLen'}."\t".
					# $dataFileBlast{$sample}{$reference}{'depthForm'}."\n";
			}
			$out = $out . $outB;
		}

		$outT = $outT . $out ."\n";
	}

	print $fh1 $header."\n".$outT . "\n";
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#gets the best virus by genus by sample
sub get_max_by_genus {
	my $variable = shift;
    my (%data) = @_;

 
    my %max;
    while (my ($sample, $genuses) = each %data) {

    	while (my ($genus, $rows) = each %$genuses) {

			foreach my $row (@$rows) {

				# print "\nNOENTRA " . $max{$sample}{$genus}{$variable} ."\t". $row->{$variable};
				if (not defined $max{$sample}{$genus} ) {
		            $max{$sample}{$genus} = $row;
		            # print "\nnodef\n"; 
		        }
		        if ($max{$sample}{$genus}{$variable} < $row->{$variable}) {
		        	
		            $max{$sample}{$genus} = $row;
		            # print "\nentra" . $max{$sample}{$genus}{$variable} ."\t". $row->{$variable} . "\n";
		        }
    		}
    		 # print "\n > = == Max: " . Dumper \$max{$sample}{$genus} ; print "\n";
    	}
    	# print "Max: " . Dumper \%max;
    }
    # print "Max: " . Dumper \%max ;
    return %max;
}

#get stats
sub get_samples_stats {
	#calculate SD, Average, cut off

    my (%data) = @_;
    my %table;
	my ($sd,$average,$cutoff);
	my $array;
	my $control = 'control_190206_SNK268_A_L004_AMRW-32-48_R1';
   
   if(%data) {
	    while (my ($sample, $control1) = each %data) {
	    	if($sample ne $control){
	    		next if (! $control1->{control}->{contaminRate});
	    		push @$array, $control1->{control}->{contaminRate};
	    	}
		}
		$average = average($array);
		$sd = stdev($array);
		$cutoff = cutoff($average,$sd,2);
	}
	if($cutoff ne $cutoff + 0 ){
		return;
	}
	return ($cutoff,$sd,$average);

}

#get virus summary table
sub get_virus_summary {
	my $control = shift;
	my $cutoff = shift;
    my (%data) = @_;
    my %table;

    while (my ($sample, $genuses) = each %data) {
    	while (my ($genus, $rows) = each %$genuses) {
    		# print "contaminRate" . Dumper \$rows->{'contaminRate'};
    		my $virus = lc $rows->{'description'};
    		$virus =~ s/\.$//g;

    		#filter by highest if duplicated
    		if (not defined $table{$virus}{'maxDepthNorm'} ) {
		        $table{$virus}{'maxDepthNorm'} = $rows->{'depthNor'};
		        $table{$virus}{'maxDepthNorm'} = $rows->{'depthNor'}*$cutoff;
		    }
		    if ($table{$virus}{'maxDepthNorm'} < $rows->{'depthNor'}) {		        	
		        $table{$virus}{'maxDepthNorm'} = $rows->{'depthNor'};
		        $table{$virus}{'coverageCutoff'} = $rows->{'depthNor'}*$cutoff;
		    }
		}
	}
	return %table;

}

sub print_summaryR {
	my $filename =shift;
	my $spikeList = shift;
	my $samples = shift;

	my (%data) = @_; #same as results

	$filename = "test1/Summary_analisis_table.tsv";
	
	#read columns to print 
	open(FILE, '<', "test1/variables.tsv") or die $!;
	my @columns;
	while (my $line=<FILE>) {
		my @field = split /\t/, $line;
		push @columns, {
			$field[0] => trim($field[1]),
		}
	}


	#create a plain hash from results. easy to print 
	my %resultsformatted;

	for my $sample (@{$samples}){ print Dumper $sample;
		$sample =~ s/\.clean\.fastq$//g;
		$sample =~ s/\.clean\.fq$//g;
		$sample =~ s/\.clean$//g;
		$sample =~ s/\.fastq$//g;
		$sample =~ s/\.fq$//g;
		my $blast = $data{$sample}{'blast'};
		if($blast){
			for my  $rows (@$blast) {
				%{$rows} = ( %{$rows}, %{$data{$sample}{'trimming'}}) if $data{$sample}{'trimming'};
				%{$rows} = ( %{$rows}, %{$data{$sample}{'sRNA'}}) if $data{$sample}{'sRNA'};
				%{$rows} = ( %{$rows}, %{$data{$sample}{'control'}}) if ($data{$sample}{'control'});
				%{$rows} = ( %{$rows}, %{$data{$sample}{'spike'}}) if $data{$sample}{'spike'};
				push @{$resultsformatted{$sample}}, $rows;
			}
		} else {
			my $rows = {};
			%{$rows} = ( %{$rows}, %{$data{$sample}{'trimming'}}) if $data{$sample}{'trimming'};
			%{$rows} = ( %{$rows}, %{$data{$sample}{'sRNA'}}) if $data{$sample}{'sRNA'};
			%{$rows} = ( %{$rows}, %{$data{$sample}{'control'}}) if ($data{$sample}{'control'});
			%{$rows} = ( %{$rows}, %{$data{$sample}{'spike'}}) if $data{$sample}{'spike'};
			push @{$resultsformatted{$sample}}, $rows;
		}
	}

	#print headers and then values according to file
	open(FH, '>', $filename) or die $!;
	print FH "Sample\t";

	foreach my $column(@columns){
		my @header = values $column;
		
		if ($header[0] eq 'spike'){
			foreach my $spike (@$spikeList){
				print FH "spike " . $spike . "\t";
			}
		} else {
			print FH $header[0] . "\t";
		}
	}

	print FH "\n";
	for my $sample (@{$samples}){ print Dumper \$sample;
		$sample =~ s/\.clean\.fastq$//g;
		$sample =~ s/\.clean\.fq$//g;
		$sample =~ s/\.clean$//g;
		$sample =~ s/\.fastq$//g;
		$sample =~ s/\.fq$//g;

		for my $rows (@{$resultsformatted{$sample}}) {
			print FH $sample . "\t";
			foreach (@columns){
				my @variable = keys $_;

				#print normal columns 
				if ($variable[0] ne 'spike'){
					if($rows->{$variable[0]}){
						print FH $rows->{$variable[0]} ."\t";
					} else {
						print FH "NA\t";
					}
				#print spikes
				} else {
					foreach my $spike (@$spikeList){
						# print "spike " . $spike . "\t";
						if($rows->{$spike}){
							print FH $rows->{$spike} ."\t";
						} else {
							print FH "NA\t";
						}
					}
				}
			}
			print FH "\n";
		}
	}
}


sub cutoff {
	my $average = shift;
	my $sd = shift;
	my $times = shift;

	return $average + ($sd * $times);
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

###borrar:

sub average{
	my $data = shift;
	if (not @$data) {
		warn("Empty array!");
		return 0;
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
