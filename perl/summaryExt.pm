use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Spec::Functions 'catfile';
use List::Util qw(reduce);

sub concat_blast {
	my $dir = shift;
	my @array_files = @_;
	my $sumBlastxn = "Sample\tBlast\tReference\tLength\tCoverage\tCoverage(%) contig\tDepth\tDepth (Norm)\tIdentity\tIden Max\tIden Min\tGenus\tDescription\n" ;

	foreach my $sample (@array_files) {
		$sample = basename($sample);

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
					$sumBlastxn .= $line if ($line !~ /^Sample/);
		        }
		        close $in;
		    }
		}
		close $out;
	}
	open my $outS, '>', catfile($dir , "Summary_blast.tab") or warn "Could not open blastxn summary for appending\n";
	print $outS $sumBlastxn;
	close $outS
}

sub print_summary0 {
	my $dir = shift;
	my $trim = catfile($dir,shift);
	my $control = catfile($dir,shift);
	my $spikeFile = catfile($dir,shift);
	my $sRNA = catfile($dir,shift);
	my $spike = shift;
	my $controlSample = shift;
	my $localdir = shift;
	my $controlseq = shift;
	my @array_files = @_;
	
	my @spikes = split /,/, $spike;
	my @controls = split /,/, $controlseq;
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
				$results{$sample.".clean.fq"}{"trimming"}{raw}   = trim($field[1]);  
				$results{$sample.".clean.fq"}{"trimming"}{clean}   = trim($field[8]) > 0  ? trim($field[8]) : trim($field[1]);
				$results{$sample}{"trimming"}{raw}   = trim($field[1]);  
				$results{$sample}{"trimming"}{clean}   = trim($field[8]) > 0  ? trim($field[8]) : trim($field[1]);
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
	my %contaminRateControl;

	if (-e -s $control){
	
		open FILE2, "$control" or warn;
		while (my $line=<FILE2>) {
			# chomp;
			next if($line =~ /^File/); 
			my @field = split /\t/, $line;
			my ($controlIndex) = grep { $controls[$_] eq $field[1] } (0 .. @controls-1);

			if (length(trim($field[0])) > 0 && trim($field[0]) eq $controlSample){
				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;
				my $sum = $results{$sample}{"sRNA"}{'sum21-24'};
				if ($sum > 0 ) {
					my $perMapControl = trim($field[9]);
					if (index($perMapControl, '%') != -1) { $perMapControl =~ s/%$//g; $perMapControl =$perMapControl/100}
					$contaminRateControl{$controlIndex}   = $perMapControl/$results{$sample}{"sRNA"}{'sum21-24'} ;
				}
			}
		}
		open FILE, "$control" or warn;

		while (my $line1=<FILE>) {
			next if($line1 =~ /^File/);
			my @field = split /\t/, $line1;
			my ($controlIndex) = grep { $controls[$_] eq $field[1] } (0 .. @controls-1);
			
			if (length(trim($field[0])) > 0){
			   	#Control sequence coverage
				$dataFile1{trim($field[0])}{concov}   = trim($field[3]); 
				#Norm deph
				$dataFile1{trim($field[0])}{depth}   = trim($field[5]);  
				#Norm deph kb
				$dataFile1{trim($field[0])}{kb}   = trim($field[6]);
				##Mapped reads to control
				$dataFile1{trim($field[0])}{numMapControl}   = trim($field[8]);
				#%Mapped reads to control
				$dataFile1{trim($field[0])}{permap}   = trim($field[9]);
				##Raw reads
				$dataFile1{trim($field[0])}{controlRaw}   = trim($field[7]);

				my $sample = trim($field[0]);
				$sample =~ s/\.clean\.fastq$//g;
				$sample =~ s/\.clean\.fq$//g;
				$sample =~ s/\.clean$//g;
				$sample =~ s/\.fastq$//g;
				$sample =~ s/\.fq$//g;
				#Control sequence name
				$results{$sample}{"control"}{$controlIndex. ":name"}   = trim($field[1]); 
				#Control sequence coverage
				$results{$sample}{"control"}{$controlIndex. ":concov"}   = trim($field[3]); 
				#Norm deph
				$results{$sample}{"control"}{$controlIndex. ":depth"}   = trim($field[5]);  
				#Norm deph kb
				$results{$sample}{"control"}{$controlIndex. ":kb"}   = trim($field[6]);
				##Mapped reads to control
				$results{$sample}{"control"}{$controlIndex. ":numMapControl"}   = trim($field[8]); 
				#%Mapped reads to control
				$results{$sample}{"control"}{$controlIndex. ":permap"}   = trim($field[9]);
				##Raw reads
				$results{$sample}{"control"}{$controlIndex. ":raw"}   = trim($field[7]);
				#%Mapped reads (21-24nts) to control
				my $sum = $results{$sample}{"sRNA"}{'sum21-24'} ? $results{$sample}{"sRNA"}{'sum21-24'} : 0;
				my $per2124MapControl = '0';
				if ($sum > 0 ) {
					my $perMapControl = trim($field[9]);
					if (index($perMapControl, '%') != -1) { $perMapControl =~ s/%$//g; $perMapControl =$perMapControl/100}
					$per2124MapControl   = $perMapControl/$results{$sample}{"sRNA"}{'sum21-24'} ;
				}
				$results{$sample}{"control"}{$controlIndex. ":per2124MapControl"} = $per2124MapControl;
				if ($contaminRateControl{$controlIndex} && $per2124MapControl ne '0') {
					$results{$sample}{"control"}{$controlIndex. ":contaminRate"}   = $per2124MapControl/$contaminRateControl{$controlIndex};
				} else {
					$results{$sample}{"control"}{$controlIndex. ":contaminRate"}   = 0;
				}
			}
		}
	}

	#Get spike in results
	my %dataFile2;

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
	
	#get host counts	
	foreach my $file (@array_files) {
		my $sample = basename($file);
		$sample =~ s/\.clean\.fastq$//g;
		$sample =~ s/\.clean\.fq$//g;
		$sample =~ s/\.clean$//g;
		$sample =~ s/\.fastq$//g;
		$sample =~ s/\.fq$//g;
		my $hostSample = $file . ".host_removed.txt";
		if (-e -s $hostSample){
			open FILE, "$hostSample" or warn;
			while (my $line1=<FILE>) {
				my @field = split /\t/, $line1;
				if (length(trim($field[0])) > 0){
					$results{$sample}{"control"}{$field[0]} += trim($field[1]);
				}
			}
		}
	}


	#Get blast results
	my %dataFileBlast;

	foreach my $file (@array_files) {
		$file = basename($file);

		my $fileBlast = catfile($dir ,"result_$file" , "blastxn.tab");
		
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
	my %dataFileBlastFiltered = get_max_by_genus('depthNor', %dataFileBlast);

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
	my $cutoff = get_samples_stats($controlSample,%results);
	if($cutoff){
		my %virusCutoff = get_virus_summary($cutoff,%dataFileBlastFiltered);

		while (my ($sample, $resultType) = each %results) {

	    	while (my ($type, $arrayEntries) = each %$resultType) {
	    		next if($type ne 'blast');

	    		for my $i (0 .. scalar @{$arrayEntries}) {  
	    			if(@{$arrayEntries}[$i]){
		    			my $virusName = lc @{$arrayEntries}[$i]->{description};
		    			$virusName =~ s/\.$//g;
		    			if($virusCutoff{$virusName}){
		    				foreach my $key (keys %$cutoff){
		    					$results{$sample}{'blast'}[$i]{$key. ':coverageCutoff'} = $virusCutoff{$virusName}{$key. ':coverageCutoff'};
		    				}
		    			}
		    		}
	    		}
	    	}
	    }
	}

	print_summaryR(catfile($dir,"Summary_analisis_table.tsv"), \@spikes,\@array_files, $localdir, %results);

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

				if (not defined $max{$sample}{$genus} ) {
		            $max{$sample}{$genus} = $row;
		        }
		        if ($max{$sample}{$genus}{$variable} < $row->{$variable}) {
		        	
		            $max{$sample}{$genus} = $row;
		        }
    		}
    	}
    }
    return %max;
}

#get stats
sub get_samples_stats {
	#calculate SD, Average, cut off
	my $control = shift;
    my (%data) = @_;
    my %table;
	my ($sd0,$average0,$sd1,$average1);
	my %cutoff;
	my $array0;
	my $array1;

	$control =~ s/\.clean\.fastq$//g;
	$control =~ s/\.clean\.fq$//g;
	$control =~ s/\.clean$//g;
	$control =~ s/\.fastq$//g;
	$control =~ s/\.fq$//g;

   if(%data) {
	    while (my ($sample, $control1) = each %data) {
	    	if($sample ne $control){
	    		next if (! $control1->{control}->{"0:contaminRate"});
	    		push @$array0, $control1->{control}->{"0:contaminRate"};
	    		push @$array1, $control1->{control}->{"1:contaminRate"};
	    	}
		}
		$average0 = average($array0);
		$average1 = average($array1);
		$sd0 = stdev($array0);
		$sd1 = stdev($array1);
		$cutoff{0} = cutoff($average0,$sd0,2);
		$cutoff{1} = cutoff($average1,$sd1,2);
	}
	if( ($cutoff{0} ne $cutoff{0} + 0) || ($cutoff{1} ne $cutoff{1} + 0) ){
		return;
	}
	return \%cutoff;

}

#get virus summary table
sub get_virus_summary {
	my $cutoff = shift;
    my (%data) = @_;
    my %table;

    while (my ($sample, $genuses) = each %data) {
    	while (my ($genus, $rows) = each %$genuses) {

    		my $virus = lc $rows->{'description'};
    		$virus =~ s/\.$//g;

    		#filter by highest if duplicated
    		if (not defined $table{$virus}{'maxDepthNorm'} ) {
		        $table{$virus}{'maxDepthNorm'} = $rows->{'depthNor'};
		        foreach my $key (keys %$cutoff){
		        	$table{$virus}{$key. ':coverageCutoff'} = $rows->{'depthNor'}*$cutoff->{$key};
		    	}
		    }
		    if ($table{$virus}{'maxDepthNorm'} < $rows->{'depthNor'}) {		        	
		        $table{$virus}{'maxDepthNorm'} = $rows->{'depthNor'};
		        foreach my $key (keys %$cutoff){
		        	$table{$virus}{$key. ':coverageCutoff'} = $rows->{'depthNor'}*$cutoff->{$key};
		    	}
		    }
		}
	}
	return %table;

}

sub print_summaryR {
	my $filename =shift;
	my $spikeList = shift;	
	my $samples = shift;	
	my $localdir = shift;

	my (%data) = @_;

	#read columns to print 
	open(FILE, '<', catfile($localdir,"perl","variables.tsv")) or warn $!;
	my @columns;
	while (my $line=<FILE>) {
		my @field = split /\t/, $line;
		push @columns, {
			$field[0] => trim($field[1]),
		}
	}


	#create a plain hash from results. easy to print 
	my %resultsformatted;
	for my $sample (@{$samples}){
		
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
	open(FH, '>', $filename) or warn $!;
	print FH "Sample\t";

	foreach my $column(@columns){
		my @header = values %{$column};
		
		if ($header[0] eq 'spike'){
			foreach my $spike (@$spikeList){
				print FH "spike " . $spike . "\t";
			}
		} else {
			print FH $header[0] . "\t";
		}
	}

	print FH "\n";
	for my $sample (@{$samples}){
		$sample =~ s/\.clean\.fastq$//g;
		$sample =~ s/\.clean\.fq$//g;
		$sample =~ s/\.clean$//g;
		$sample =~ s/\.fastq$//g;
		$sample =~ s/\.fq$//g;

		foreach my $rows (@{$resultsformatted{$sample}}) {
			print FH $sample . "\t";
			foreach (@columns){
				my @variable = keys %{$_};

				#print normal columns 
				if ($variable[0] ne 'spike'){
					my $columnVar = qq|$variable[0]|;
					if(exists($rows->{$columnVar})  ){
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


1;