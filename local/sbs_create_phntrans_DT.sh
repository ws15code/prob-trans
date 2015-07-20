#!/bin/bash -u

set -o errexit
set -o pipefail
export LC_ALL=C

# ./local/sbs_prepare_files_DT.sh --corpus-dir="/export/ws15-pt-data/data/audio"  --trans-dir="/export/ws15-pt-data/data/transcripts/matched" --list-dir="/export/ws15-pt-data/amitdas/lists" --lang-map="conf/lang_codes.txt" --eng-ipa-map="conf/eng/eng-ARPA2IPA.txt" --eng-dict="conf/eng/eng-cmu-dict.txt" "DT"
# ./local/sbs_create_phntrans_DT.sh --g2p conf/dutch/g2pmap.txt --utts ../../../amitdas/train_basenames_wav --transdir /export/ws15-pt-data/data/transcripts/matched/dutch

errecho() { echo -e "$@" >&2; }
# some default settings
corpusdir=/export/ws15-pt-data/data
tmpdir=local/tmp/DT

# scp
uttidlist="$tmpdir/uttid.txt"
rawtransdir="$corpusdir/transcripts/matched/dutch"
rawtransscp="$tmpdir/trans_raw.scp"
normtransscp="$tmpdir/trans_norm.scp"

# fst
engfsttxt="$corpusdir/misc/engtag.fst.txt"
engfstbin="$tmpdir/engtag.fst.bin"
g2pfsttxt="conf/dutch/g2pmap.txt"
g2pfstbin="$tmpdir/g2pmap.fst.bin"
unionfsttxt="$tmpdir/U.fst.txt"
unionfstbin="$tmpdir/U.fst.bin"
fsadir=$tmpdir/fsa

# dictionary for english words present in Dutch transcripts
tagdict="conf/dutch/numbers_dutch_pron.ipa.dict"

# symbols
epssym="eps" # epsilon symbol used in FSTs
silword="<silence>"
l2tag="<EN>"

# options for this script
g2p=$g2pfsttxt
utts=$uttidlist
transdir=$rawtransdir

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

g2pfsttxt=$g2p
uttidlist=$utts
rawtransdir=$transdir

mkdir -p $tmpdir 
errecho "\nBegin converting word trans --> phone trans for uttids in $uttidlist"


if [[ 0 == 1 ]]; then
# extract raw transcriptions and save them in scp format
:
fi

[ ! -z $utts ] || ls -1 $rawtransdir|sed 's:.txt::' > $uttidlist
perl local/sbs_extract_trans_DT.pl --d $rawtransdir --e "txt"   $uttidlist > $rawtransscp
sed -i "s/$l2tag//g" $rawtransscp # remove L2 tags (optional step - useful if you see too many L2 words in L1 text!!)

# tag special words with <EN>
# cat $rawtransscp |cut -d' ' -f2-|grep -iE "[0-9]" > conf/dutch/numbers_eng_pron.cmu.dict
#perl local/transnorm.pl <(cat conf/dutch/numbers_eng_pron.cmu.dict|tr '[:upper:]' '[:lower:]') conf/eng/eng-ARPA2IPA.txt > conf/dutch/numbers_eng_pron.ipa.dict
# After this, I manually modified  the Eng pronunciations in "numbers_eng_pron.ipa.dict" to make them Dutch pronunciations which are
# saved in conf/dutch/numbers_dutch_pron.ipa.dict <-- this is the one we want to use 

# normalize transcriptions (but skip normalizing L2 words which are tagged using $l2tag)
transscptmp=$(mktemp)
local/sbs_norm_trans_DT.pl --i $rawtransscp --sil $silword --l2tag $l2tag > $transscptmp

# if words from "$tagdict" are present in transcription, then these words should be expanded to their phone sequences
# and tagged using L2 tags!! E.g. If an entry "4  v i r" is present in $tagdict and "4" occurs in transcription, then convert 4 to <EN>v i r<EN>
local/sbs_norm_trans_DT.pl --i $transscptmp  --l2tag $l2tag --tagdict $tagdict > $normtransscp


# Note: L1 = Dutch, L2 = English
## create vocab for English 
errecho "Creating phone vocab for P2P English: vocab=$tmpdir/EN.vocab ... "
cat $engfsttxt| awk '{print $3}'|sed '/^ *$/d'|sort -u| awk 'BEGIN {ind = 1}; {print $1, ind; ind++}' > $tmpdir/EN.vocab

## create vocab for G2P Dutch
errecho "Creating vocab for G2P Dutch: grapheme vocab=$tmpdir/DT.ortho.vocab, phone vocab = $tmpdir/DT.phone.vocab ... "
echo "$epssym  0" > $tmpdir/DT.ortho.vocab
cat $g2pfsttxt|awk '{print $3}'|sed '/^ *$/d'|sort -u| grep -vi "$epssym"| awk 'BEGIN {ind = 1}; {print $1, ind; ind++}' >> $tmpdir/DT.ortho.vocab

echo "$epssym  0" > $tmpdir/DT.phone.vocab
cat $g2pfsttxt|awk '{print $4}'|sed '/^ *$/d'|sort -u| grep -vi "$epssym"| awk 'BEGIN {ind = 1}; {print $1, ind; ind++}' >> $tmpdir/DT.phone.vocab

## create fsts: G2P Dutch, P2P English, and Union fst (U) 
# create input vocab of U (also, add L2 tag to the last entry of vocab)
perl local/make_unique_ids.pl $tmpdir/DT.ortho.vocab $tmpdir/EN.vocab > $tmpdir/U.input.vocab
gind=`cut -d' ' -f2 $tmpdir/U.input.vocab | tail -1`
gind=`expr $gind + 1`
echo "<EN> $gind" >> $tmpdir/U.input.vocab

# create output vocab of U
perl local/make_unique_ids.pl $tmpdir/DT.phone.vocab $tmpdir/EN.vocab > $tmpdir/U.output.vocab

# compile Eng FST
errecho "Creating English P2P FST = $engfstbin ..."
fstcompile --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $engfsttxt $engfstbin
# diagnostic
fstdraw  --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $engfstbin | dot -Tpdf  > $tmpdir/Eng.fst.pdf

# compile G2P Dutch FST
errecho "Creating G2P Dutch FST = $g2pfstbin ..."
fstcompile --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $g2pfsttxt $g2pfstbin
# diagnostic
fstdraw  --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $g2pfstbin | dot -Tpdf  > $tmpdir/g2pmap.fst.pdf

# create U = Union (Eng, G2P)
errecho "Creating Union FST = $unionfstbin ..."
fstunion $g2pfstbin $engfstbin | fstclosure - > $unionfstbin

# modify U.fst to add the symbol for L2 tag ($l2tag)
# diagnostic
fstdraw  --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $unionfstbin | dot -Tpdf  > $tmpdir/U.fst.tmp.pdf
fstprint --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $unionfstbin > $tmpdir/U.fst.tmp.txt
cat $tmpdir/U.fst.tmp.txt|\
awk -v l2tag=$l2tag '{	
	if (1 != NF) { # if non-terminal node
		printf "%d\t%d\t", $1, $2; 
		if ( ($1 == 0 && $2 == 16) || ($1 == 16 && $2 == 0) ) 
			printf "%s\t", l2tag;
		else 
			printf "%s\t",$3;  
		printf "%s\n",$4;
	} else # for terminal nodes, print only terminal node number
		printf "%d\n", $1;	
}' > $unionfsttxt 

# convert the integer fst to symbol fst
#perl local/int2symfst.pl --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab  $unionfsttxt
#exit 1;

# regenerate U.fst to incorporate the addition of L2 tag 
fstcompile --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $unionfsttxt $unionfstbin
# diagnostics
fstdraw  --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $unionfstbin| dot -Tpdf > $tmpdir/U.fst.pdf
fstprint --isymbols=$tmpdir/U.input.vocab --osymbols=$tmpdir/U.output.vocab $unionfstbin > $unionfsttxt

# create fsa for Dutch sentences (some sentences have L2 words)
errecho "Creating Dutch FSA ... "
mkdir -p $tmpdir/fsa
rm -rf $tmpdir/fsa/*

#echo "$epssym  0" > $tmpdir/trans.vocab
#cat $engfsttxt $g2pfsttxt <(echo "1 1 $l2tag $l2tag")|awk '{print $3}'|sed '/^ *$/d'|sort -u|grep -vi "$epssym"|\
#awk 'BEGIN {ind = 1}; {print $1, ind; ind++}' >> $tmpdir/trans.vocab
#local/spell2fst.pl --odir $fsadir --vocab $tmpdir/trans.vocab --sil "<silence>" --l2tag $l2tag < $normtransscp
local/spell2fst.pl --odir $fsadir --vocab $tmpdir/U.input.vocab --sil $silword --l2tag $l2tag < $normtransscp

# Compose Dutch FSA with Union.fst. Print best path
errecho "Composing Dutch FSA with Union FST ... "
while read -r line; do
	uttid=`printf "$line" | cut -f1`
	fsa="$fsadir/$uttid.fst"
	[ -f $fsa ] || { echo "$fsa does not exist"; exit 1; }
	phnseq=`fstarcsort --sort_type=olabel $fsa | fstcompose - $unionfstbin  | fstshortestpath | fstprint --osymbols=$tmpdir/U.output.vocab | ./local/reversepath.pl | sed "s/$epssym//g"`
	echo -e "$uttid\t$phnseq";	
done < $uttidlist
errecho -e "DONE Generating transcripts\n"

