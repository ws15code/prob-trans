#!/bin/bash

# Adapted from Kaldi scripts. Please see COPYING for more details.

# Apache 2.0.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.

# Call this script from the parent directory of the trained mismatched ASR system.
# Typically named s3/ or s5/ in the Kaldi directory structure.

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
[ -f path.sh ] && . ./path.sh; #source the path

# Begin configuration section.  
if [ $# -ne 1 ]; then
	echo "Usage: $0 <settings file>"
	exit 1;
fi

. $1 #source the settings file


lmdir=$localdir/$tgtlmdir

lm_text=$datadir/lm_text
lexicon=$localdir/$tgtdict/lexicon.txt 


for f in "$lm_text" "$lexicon"; do
  [ ! -f $x ] && echo "$0: No such file $f" && exit 1;
done

# It assumes you have already run
# swbd_p1_data_prep.sh.  
# It takes as input the files
#data/local/train/text
#data/local/dict/lexicon.txt

mkdir -p $lmdir
export LC_ALL=C # You'll get errors about things being not sorted, if you
# have a different locale.
export PATH=$PATH:`pwd`/../../tools/kaldi_lm
( # First make sure the kaldi_lm toolkit is installed.
 cd ../../tools || exit 1;
 if [ -d kaldi_lm ]; then
   echo Not installing the kaldi_lm toolkit since it is already there.
 else
   echo Downloading and installing the kaldi_lm tools
   if [ ! -f kaldi_lm.tar.gz ]; then
     wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1;
   fi
   tar -xvzf kaldi_lm.tar.gz || exit 1;
   cd kaldi_lm
   make || exit 1;
   echo Done making the kaldi_lm tools
 fi
) || exit 1;


cleantext=$lmdir/text.no_oov

cat $lm_text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } } 
  {for(n=1; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<UNK> ");} } printf("\n");}' \
  > $cleantext || exit 1;


cat $cleantext | awk '{for(n=1;n<=NF;n++) print $n; }' | sort | uniq -c | \
   sort -nr > $lmdir/word.counts || exit 1;


# Get counts from acoustic training transcripts, and add  one-count
# for each word in the lexicon (but not silence, we don't want it
# in the LM-- we'll add it optionally later).
cat $cleantext | awk '{for(n=1;n<=NF;n++) print $n; }' | \
  cat - <(grep -w -v '!SIL' $lexicon | awk '{print $1}') | \
   sort | uniq -c | sort -nr > $lmdir/unigram.counts || exit 1;

# note: we probably won't really make use of <UNK> as there aren't any OOVs
cat $lmdir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<UNK>" > $lmdir/word_map \
   || exit 1;

# note: ignore 1st field of train.txt, it's the utterance-id.
cat $cleantext | awk -v wmap=$lmdir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
  { for(n=1;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print ""; }}}' | gzip -c >$lmdir/train.gz \
   || exit 1;

train_lm.sh --arpa --lmtype 3gram-mincount $lmdir || exit 1;

echo "Done creating trigram language model in ARPA format."

# note: output is
# $datadir/local/lm/3gram-mincount/lm_unpruned.gz 


silprob=0.5
mkdir -p $datadir/$tgtlangtest

arpa_lm=$lmdir/3gram-mincount/lm_unpruned.gz
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

# Copy stuff into its final locations...
cp -r $datadir/$tgtlang/phones $datadir/$tgtlangtest
cp $datadir/$tgtlang/* $datadir/$tgtlangtest 2>/dev/null

# grep -v '<s> <s>' etc. is only for future-proofing this script.  Our
# LM doesn't have these "invalid combinations".  These can cause 
# determinization failures of CLG [ends up being epsilon cycles].
# Note: remove_oovs.pl takes a list of words in the LM that aren't in
# our word list.  Since our LM doesn't have any, we just give it
# /dev/null [we leave it in the script to show how you'd do it].
gunzip -c "$arpa_lm" | \
   grep -v '<s> <s>' | \
   grep -v '</s> <s>' | \
   grep -v '</s> </s>' | \
   arpa2fst - | fstprint | \
   utils/remove_oovs.pl /dev/null | \
   utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$datadir/$tgtlangtest/words.txt \
     --osymbols=$datadir/$tgtlangtest/words.txt  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon > $datadir/$tgtlangtest/G.fst
  fstisstochastic $datadir/$tgtlangtest/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $datadir/$tgtlangtest/G.fst 

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
fstprint   --isymbols=$datadir/$tgtlang/phones.txt --osymbols=$datadir/$tgtlang/words.txt $datadir/$tgtlang/L.fst  | head

echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize $datadir/$tgtlangtest/G.fst /dev/null || echo Error determinizing G.

# Checking that L_disambig.fst is determinizable.
fstdeterminize $datadir/$tgtlangtest/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose $datadir/$tgtlangtest/L_disambig.fst $datadir/$tgtlangtest/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose $datadir/$tgtlang/L_disambig.fst $datadir/$tgtlangtest/G.fst | \
   fstisstochastic || echo LG is not stochastic


echo $0 succeeded.


