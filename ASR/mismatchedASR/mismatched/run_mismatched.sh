#!/bin/bash

# Adapted from Kaldi scripts. Please see COPYING for more details.

# Apache 2.0

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


. ./cmd.sh
[ -f path.sh ] && . ./path.sh; #source the path

# Begin configuration section.  
if [ $# -ne 1 ]; then
	echo "Usage: $0 <settings file>"
	exit 1;
fi

. $1 #source the settings file

# INITIALIZATIONS

#data independent of source language ASR


echo ============================================================================
echo "                Phone Lexicon & Language Preparation                     "
echo ============================================================================

# In data prep, prepare utt2spk etc., copy hindi lexicon to data/local/dict_hindi/
local/mismatched_data_prep.sh $1 || exit 1;

# create phones.txt, words,txt, L.fst for the target language
utils/prepare_lang.sh --position-dependent-phones false --num-sil-states 3 \
 $localdir/$tgtdict "<UNK>" $localdir/lang_tmp $datadir/$tgtlang || exit 1;

# create G.fst in here
local/mismatched_format_data.sh $1 || exit 1;

echo ============================================================================
echo "         MFCC Feature Extration & CMVN from new language audio      "
echo ============================================================================

steps/make_mfcc.sh --cmd "$train_cmd" --nj 30 $datadir $expdir/make_mfcc $mfccdir || exit 1;
steps/compute_cmvn_stats.sh $datadir $expdir/make_mfcc $mfccdir || exit 1;

echo ============================================================================
echo "                     Decoding Phone Lattices                        "
echo "                     Using trained HMM-GMMs                         "
echo ============================================================================

#create mismatched mkgraph.sh which also takes as input srcxtgt.fst
local/mismatched_mkgraph.sh $1 || exit 1;

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 $expdir/$tgtgraphdir $datadir $expdir/$tgtdecodedir || exit 1;

echo ============================================================================
echo "Finished successfully on" `date`
echo ============================================================================

exit 0
