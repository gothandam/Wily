#!/bin/bash
tput smso; echo "$ ~~~Starting WILY afresh $" 
tput rmso;
tput smso; echo "$ Looking for dependent programs of this pipeline one by one!$" 
tput rmso;
tput smso; echo " $ Please input password as and when the terminal prompts to$" 
tput rmso;
if flye --help; then
tput smso; echo "$ FLye available and it is all good!$" 
tput rmso;
else 
pip install flye
fi
if circlator; then
tput setab7 ; echo "$ Circlator available and it is all good$" 
tput rmso;
else 
sudo apt install circlator spades 
fi
if porechop --version; then
tput smso; echo "$ Porechop available and it is all good!$" 
tput rmso;
else sudo apt install porechop
fi
if apt install minimap2 racon; then
tput smso; echo "$ All dependencies available, proceeding ahead $" 
tput rmso;
else 
echo "Some programs could not be fixed/unavailable, Wily may proceed with error $" 
tput rmso;
fi
sudo apt install figlet toilet ||
sudo apt install boxes ||
echo ""
clear;
tput blink; figlet -c -t This is WILY	FOR  NANOPORE; 
tput sgr0; 
/bin/sleep 3
clear
echo ""
echo ""
echo "This program recursively enters every folder in the current directory and looks for fastq files" | boxes -d boy
/bin/sleep 5
echo ""
echo ""
echo ""
path=$PWD
for d in $path/*; do
cd $d &&
tput smso; echo "$~~~In every directory,an assembly folder will be created where the flye assembly outputs can be found~~~$"; tput rmso;
mkdir assembly
path2=$PWD
tput smso; echo "$~~~Concatenates all fastq files in the barcode folder~~~~$" ; tput rmso;
cat *.fastq > merged.fastq &&
tput smso; echo "$ ~~~Reads are filtered with filtlong, however 90 percent of the total reads will be kept~~~$" tput rmso;
/usr/local/bin/Filtlong/bin/filtlong --min_length 1000 --keep_percent 90 merged.fastq > filtout.fastq &&
tput smso; echo "$ ~~~Filtered outputs are passed to porechop tool to remove adapters~~~$" tput rmso;
porechop -i filtout.fastq -o porechoped.fastq &&
tput smso; echo "$ ~~~Adapter removed reads are now passed into flye assembler in normal mode~~~$" tput rmso;
flye --nano-raw porechoped.fastq -t 4 --out-dir $path2/assembly -t 8 &&
tput smso; echo "$ ~~~Outputs from flye and porechop are used to circularise the assembly~~~$" tput rmso;
circlator all --data_type nanopore-raw --bwa_opts "-x ont2d" --merge_min_id 85 --merge_breaklen 1000 $path2/assembly/assembly.fasta $path2/porechoped.fastq $path2/circularised --threads 8
tput smso; echo " $  ~~~Starting polishing step~~~ $" tput rmso;
minimap2 -x ava-ont $path2/circularised/06.fixstart.fasta $path2/porechoped.fastq > overlaps.paf ||
minimap2 -x ava-ont $path2/assembly/assembly.fasta $path2/porechoped.fastq > overlaps.paf
racon $path2/porechoped.fastq overlaps.paf $path2/circularised/06.fixstart.fasta -t 8 > polish.assembly.fasta ||
racon $path2/porechoped.fastq overlaps.paf $path2/assembly/assembly.fasta -t 8 > polish.assembly.fasta
tput smso; echo "$ Creating report for the current barcode file at $path$ " tput rmso;
fastqc porechoped.fastq ||
mkdir $path2/Reports
grep "Overlap-based coverage:" $path2/assembly/flye.log > $path2/Reports/flyecoverage.txt
mv $path2/porechoped_fastqc.html $path2/Reports 
tput smso; echo "$ Encrypting files to prevent corruption, this may take a while!$" tput rmso;
tar -zcf assembly.tar.gz assembly
tar -zcf circularised.tar.gz circularised
tar -cf rawfiles.tar porechoped.fastq filtout.fastq merged.fastq
tar -cf polishedassembly.tar polish.assembly.fasta
clear
done
