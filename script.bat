
REM mkdir c:\perlfiles
REM PowerShell Expand-Archive -Path "bin\strawberry-perl-5.28.0.1-64bit-portable.zip" -DestinationPath "c:\perlfiles"
REM c:\perlfiles\portableshell.bat
cpan Bio::SeqIO


C:\Users\mire_\Downloads\VirusDetect-master\VirusDetect-master\bin\bwa samse -n 10000 ..\databases\vrl_plant bwa.sai test_data > test_data.sam

perl virus_detect.pl --reference databases\vrl_plant test_data