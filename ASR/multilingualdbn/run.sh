#!/bin/bash


cmvn_optsf=
delta_optsf=
splice_optsf=
#desired_lang="albanian  bangla   cookislands-maori  dinka     finnish   hebrew      italian   kurdish     malay      norwegian      punjabi   sinhalese  swahili   tongan
#amharic   bosnian    croatian    dutch     french    hindi       japanese  lao         malayalam  pashto         romanian  slovak     swedish   turkish
#arabic    bulgarian  czech    estonian  german    hmong       kannada   latvian     maltese    persian-farsi  russian   slovenian  tamil     ukrainian
#armenian  burmese    danish   fijian    greek     hungarian   khmer     lithuanian  mandarin   polish         samoan    somali     thai      urdu
#assyrian  cantonese  dari    filipino  gujarati  indonesian  korean    macedonian  nepali     portuguese     serbian   spanish    tigrinya  vietnamese"

#desired_lang="arabic"

echo "$0 $@"  # Print the command line for logging

[[ -f path.sh ]] && . ./path.sh || { echo "path.sh does not exist"; exit 1; }
[[ -f cmd.sh ]] && . ./cmd.sh || { echo "cmd.sh does not exist"; exit 1; }
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
  echo "Usage: run.sh [options] <stage>"
  echo " e.g.:  run.sh --cmvn-optsf ../../timit/s5/exp/mono/cmvn_opts 1 "
  echo "main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config containing options"
  echo "  --nj <nj>                                        # number of parallel jobs"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --cmvn-optsf <cmvn-opts file>                     # cmvn opts file. "
  echo "  --delta-optsf <delta-opts file>                   # delta-opts file. "
  echo "  --splice-optsf <splice-opts file>                 # splice-opts file. "
  exit 1;
fi


# the main script
set -e
stage=$1

sbs=$corpus_dir/www.sbs.com.au/seg2
wsj0=$corpus_dir/wsj/wsj0
wsj1=$corpus_dir/wsj/wsj1
#music=$corpus_dir/music/wav_mono

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
dir=exp/config


if [ $stage -eq 1 ]; then
# data prep
echo "Data preparation ..."
local/make_sbs.sh $sbs data/sbs # sbs has about 1130 hours of data
#local/make_wsj.sh $wsj0/??-{?,??}.? $wsj1/??-{?,??}.? data/english

utils/combine_data.sh data/train_all data/sbs
#utils/combine_data.sh data/train data/sbs data/english 
fi

if [ $stage -eq 2 ]; then
# Generate features
echo "Feature generation ... "
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd" \
    data/train_all exp/make_mfcc $mfccdir
    
steps/compute_cmvn_stats.sh data/train_all exp/make_mfcc $mfccdir    

#sid/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" \
#    data/train exp/make_vad $vaddir

# Note: to see the proportion of voiced frames you can do,
# grep Prop exp/make_vad/vad_*.1.log 
fi

if [ $stage -eq 3 ]; then
echo "Run DBN pretraining ... "

## Get a smaller subset of training data (15k utts ~ 20 hrs) since we do not need so much of data
utils/subset_data_dir.sh data/train_all 15000 data/train

echo "Create config options in directory $dir ..."
[[ ! -d $dir ]] && mkdir -p $dir;

cmvn_opts=
delta_opts=
splice_opts=
[[ -f $cmvn_optsf ]] && cmvn_opts=`cat $cmvn_optsf`;
[[ -f $delta_optsf ]] && delta_opts=`cat $delta_optsf`;
[[ -f $splice_optsf ]] && splice_opts=`cat $splice_optsf`;

echo "$cmvn_opts"   > $dir/cmvn_opts # keep track of options to CMVN.
echo "$delta_opts"  > $dir/delta_opts # keep track of delta options.
echo "$splice_opts" > $dir/splice_opts # keep track of frame-splicing options.

# cmvn opts
# feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"
# delta opts
# feats="ark,s,cs:add-deltas $delta_opts scp:$sdata/JOB/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- | select-voiced-frames ark:- scp,s,cs:$sdata/JOB/vad.scp ark:- |"

# Karel's neural net recipe.                                                                                                                                        
local/nnet/run_dbn.sh $dir data/train 
fi

exit 0;
