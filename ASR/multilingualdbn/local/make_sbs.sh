#!/bin/bash
#
# Copyright 2010-2012 Microsoft Corporation  Johns Hopkins University (Author: Daniel Povey).  Apache 2.0.

# To be run from one directory above this script.

# The input is the 3 CDs from the LDC distribution of Resource Management.
# The script's argument is a directory which has three subdirectories:
# rm1_audio1  rm1_audio2  rm2_audio

# Note: when creating your own data preparation scripts, it's a good idea
# to make sure that the speaker id (if present) is a prefix of the utterance
# id, that the output scp file is sorted on utterance id, and that the 
# transcription file is exactly the same length as the scp file and is also
# sorted on utterance id (missing transcriptions should be removed from the
# scp file using e.g. scripts/filter_scp.pl)

if [ $# != 2 ]; then
  echo "Usage: $0 /path/to/sbs-wav  data/ directory"
  exit 1; 
fi 

WAVROOT=$1
data=$2;

tmpdir=data/local/tmp
mkdir -p $tmpdir
. ./path.sh || exit 1; # for KALDI_ROOT

if [ ! -d "${WAVROOT}" ]; then
   echo "Error: $0 requires a directory argument (an absolute pathname) that contains mp3 files"
   exit 1; 
fi  

find "$WAVROOT" -type f -iname "*.wav" > $tmpdir/train_wav.flist

[ -d "$data" ] || mkdir -p $data;
# prepare wav.scp, spk2utt, utt2spk, spk2gender files
local/make_sbs.pl $tmpdir/train_wav.flist  $data

echo "sbs data prep succeeded"
exit 0;




