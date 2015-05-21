#!/bin/sh

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <settings file> <uttid>"
	echo "Inside settings: <transfile: turker transcripts, #-delimited> <idfile: turker ids ordering, delimited by commas> <num: number of turkers to combine> <roverdir: rover files directory> <nbest: num of shortest paths> <resfile: output results file prefix> <e2h: e2h fst> <simfile: similarity score files><lmfst: LG target language fst>"
	exit 0
fi

[ ! -f $1 ] && echo "settings file expected to exist within $1" && exit 1;

. $1

uttid=$2

disfactor=1
nrand=10

mkdir -p $roverdir
>$resfile;

perl scripts/create_rover_ctm_files.pl $transfile $roverdir

luttid=`echo $uttid | tr [A-Z] [a-z]`
tmpdir=/tmp/$$.dir

mkdir -p $tmpdir

str=`grep "$uttid," $idfile`
roverarg=""

n=`expr $num + 1`
for j in `seq 2 $n`; do
	turker=`echo $str | cut -d',' -f$j`;
	tmpfile=$tmpdir/$$.$uttid.${turker}.ctm
	grep -i "$uttid " $roverdir/turker.${turker}.ctm > $tmpfile
	if [ -s $tmpfile ]; then
		roverarg=`echo $roverarg -h $tmpfile ctm`
	fi
done

# now run rover
echo Calling Rover: $roverarg
putatfile=$tmpdir/$$.${turker}.${uttid}.putat 
rover $roverarg -o $putatfile -m putat

perl scripts/rover_to_fst.pl --rerank 4 --nbhdsize 5 --discount $disfactor $transfile < $putatfile | perl scripts/prune_rover.pl --eps-special > $tmpdir/$luttid.pruned.fst.txt

if [ ! -f $tmpdir/$luttid.pruned.fst.txt ]; then
	echo "File not found: $tmpdir/$luttid.pruned.fst.txt"
	exit 1
fi

fstcompile --isymbols=data/eng-alphabet-expanded.vocab --osymbols=data/eng-alphabet-expanded.vocab $tmpdir/$luttid.pruned.fst.txt > $tmpdir/$uttid.fst

fstarcsort --sort_type=olabel $tmpdir/$uttid.fst | fstcompose - $e2h | fstarcsort --sort_type=olabel - | fstcompose - $lmfst | fstshortestpath - | fstprint --osymbols=data/hindi_words.vocab - | perl scripts/reverse_fst_path.pl "$uttid" > $resfile

rm -rf $tmpdir
