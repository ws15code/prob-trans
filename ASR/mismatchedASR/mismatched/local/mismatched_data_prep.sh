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

[ -f path.sh ] && . ./path.sh; #source the path
# Begin configuration section.  
if [ $# -ne 1 ]; then
	echo "Usage: $0 <settings file>"
	exit 1;
fi

. $1 #source the settings file

# source language ASR directories
srcmodeldir=$srcdir/$exp/$amdir
srcdictdir=$srcdir/data/local/$srcdict

# target language directories
dictdir=$localdir/$tgtdict

# files expected to exist for the target language
audio=$datadir/wav.scp
text=$datadir/text
lm_text=$datadir/lm_text
lexicon=$datadir/lexicon_nosil.txt

tmpdir=/tmp/$$.dir;

mkdir -p $dictdir
mkdir -p $expdir
mkdir -p $tmpdir

for f in $audio $text $lm_text $lexicon; do
  [ ! -f $f ] && echo "mismatched_data_prep.sh: no such file $f" && exit 1;
done

! utils/validate_dict_dir.pl $srcdictdir && \
  echo "*Error validating directory $srcdictdir*" && exit 1;

#######################################################
##### THE NEXT TWO LINES WILL CHANGE DEPENDING ########
##### ON THE FORMAT OF UTTERANCE IDS IN YOUR DATA #####
################ CHANGE APPROPRIATELY #################
#######################################################

cut -f1 -d' ' $audio > $tmpdir/uttids
cut -f1 -d'_'  $tmpdir/uttids | paste -d' ' $tmpdir/uttids - > $datadir/utt2spk
#######################################################
cat $datadir/utt2spk | utils/utt2spk_to_spk2utt.pl > $datadir/spk2utt || exit 1;

# 1. Dictionary preparation
# creating files needed to run utils/prepare_lang.sh
(echo '<SIL> SIL'; echo '<SPOKEN_NOISE> SPN'; echo '<UNK> SPN'; echo '<NOISE> NSN'; ) | \
	cat - $lexicon > $dictdir/lexicon.txt
(echo 'SIL'; echo 'SPN'; echo 'NSN'; ) > $dictdir/silence_phones.txt
echo 'SIL' > $dictdir/optional_silence.txt
cut -d' ' -f2- $lexicon | tr ' ' '\n' | sort -u | sed '/^$/d' > $dictdir/nonsilence_phones.txt
cat $dictdir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $dictdir/extra_questions.txt || exit 1;
cat $dictdir/nonsilence_phones.txt | perl -e 'while(<>){ if($_ ne "") { foreach $p (split(" ", $_)) {
  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } } foreach $l (values %q) {print "$l\n";}' \
 >> $dictdir/extra_questions.txt || exit 1;

# copying model files to $expdir
cp $srcmodeldir/*.mdl $srcmodeldir/*.mat $srcmodeldir/splice_opts $srcmodeldir/norm_vars $srcmodeldir/tree $expdir 2>/dev/null

rm -rf $tmpdir

echo "Data preparation succeeded"

exit 0
