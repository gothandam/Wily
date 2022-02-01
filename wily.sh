#!/bin/bash
echo "~~~Starting WILY afresh~~~/n"
echo "Looking for dependent programs of this pipeline one by one/n!"
echo " Please input password as and when the terminal prompts to/n"
if flye; then
echo "FLye available and it is all good! /n"
else pip install flye
fi
if circlator; then
echo "Circlator available and it is all good/n"
else sudo apt install circlator spades 
fi
if porechop; then
echo "Porechop available and it is all good! /n"
else sudo apt install porechop
fi
if sudo apt install minimap2 racon; then
echo "All dependencies available, proceeding ahead /n."
else echo "Some programs could not be fixed/unavailable, Wily may proceed with errors!"
fi
sudo apt install figlet toilet ||
sudo apt install boxes ||
figlet -c -t WILY FOR NANOPORE ||
echo "~~~This program recursively enters every folder in the current directory and looks for fastq files~~~" | boxes -d boy
path=$PWD
for d in $path/*; do
cd $d &&
echo "~~~In every directory,an assembly folder will be created where the flye assembly outputs can be found~~~"
mkdir assembly
path2=$PWD
echo "~~~Concatenates all fastq files in the barcode folder~~~~/n"
cat *.fastq > merged.fastq &&
echo "~~~Reads are filtered with filtlong, however 90 percent of the total reads will be kept~~~/n"
/usr/local/bin/Filtlong/bin/filtlong --min_length 1000 --keep_percent 90 merged.fastq > filtout.fastq &&
echo "~~~Filtered outputs are passed to porechop tool to remove adapters~~~/n"
porechop -i filtout.fastq -o porechoped.fastq &&
echo "~~~Adapter removed reads are now passed into flye assembler in normal mode~~~/n"
flye --nano-raw porechoped.fastq -t 4 --out-dir $path2/assembly -t 8 &&
echo "~~~Outputs from flye and porechop are used to circularise the assembly~~~/n"
circlator all --data_type nanopore-raw --bwa_opts "-x ont2d" --merge_min_id 85 --merge_breaklen 1000 $path2/assembly/assembly.fasta $path2/porechoped.fastq $path2/circularised --threads 8
echo " \n ~~~Starting polishing step~~~ \n"
minimap2 -x ava-ont $path2/circularised/06.fixstart.fasta $path2/porechoped.fastq > overlaps.paf ||
minimap2 -x ava-ont $path2/assembly/assembly.fasta $path2/porechoped.fastq > overlaps.paf
racon $path2/porechoped.fastq overlaps.paf $path2/circularised/06.fixstart.fasta -t 8 > polish.assembly.fasta ||
racon $path2/porechoped.fastq overlaps.paf $path2/assembly/assembly.fasta -t 8 > polish.assembly.fasta
done
