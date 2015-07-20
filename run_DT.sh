#!/bin/bash -u

# This script shows the steps needed to build a recognizer for certain matched languages (Arabic, Dutch, Mandarin, Hungarian, Swahili, Urdu) of the SBS corpus. 
# (Adapted from the egs/gp script run.sh)

echo "This shell script may run as-is on your system, but it is recommended 
that you run the commands one by one by copying and pasting into the shell."
#exit 1;

[ -f cmd.sh ] && source ./cmd.sh \
  || echo "cmd.sh not found. Jobs may not execute properly."

. path.sh || { echo "Cannot source path.sh"; exit 1; }

# Set the location of the SBS speech 
SBS_CORPUS=/export/ws15-pt-data/data/audio
SBS_TRANSCRIPTS=/export/ws15-pt-data/data/transcripts/matched
SBS_DATA_LISTS=/export/ws15-pt-data/data/lists
NUMLEAVES=1200
NUMGAUSSIANS=8000

# Set the language codes for SBS languages that we will be processing
export SBS_LANGUAGES="DT"

for ii in `seq 1 5`; do
#### LANGUAGE SPECIFIC SCRIPTS HERE ####
#local/sbs_data_prep.sh --config-dir=$PWD/conf --corpus-dir=$SBS_CORPUS \
#  --languages="$SBS_LANGUAGES"  --trans-dir=$SBS_TRANSCRIPTS --list-dir=$SBS_DATA_LISTS
SBS_DATA_LISTS=/export/ws15-pt-data/amitdas/lists
cat $SBS_DATA_LISTS/dutch/all_basenames_wav |shuf|head -n 520 > $SBS_DATA_LISTS/dutch/train.txt
comm -23 <(cat $SBS_DATA_LISTS/dutch/all_basenames_wav | sort -k1,1) <(cat $SBS_DATA_LISTS/dutch/train.txt|sort -k1,1) > $SBS_DATA_LISTS/dutch/eval.txt

./local/sbs_prepare_files_DT.sh    --corpus-dir=$SBS_CORPUS  --trans-dir=$SBS_TRANSCRIPTS \
--list-dir=$SBS_DATA_LISTS  --lang-map="conf/lang_codes.txt" \
--eng-ipa-map="conf/eng/eng-ARPA2IPA.txt" --eng-dict="conf/eng/eng-cmu-dict.txt" "DT"
#### 
echo "LANG = $SBS_LANGUAGES"
for L in $SBS_LANGUAGES; do
	local/sbs_dict_prep.sh $L | tee data/$L/prepare_dict.log
done

for L in $SBS_LANGUAGES; do
  utils/prepare_lang.sh --position-dependent-phones false \
    data/$L/local/dict "<unk>" data/$L/local/lang_tmp data/$L/lang \
    | tee data/$L/prepare_lang.log || exit 1;
done

for L in $SBS_LANGUAGES; do
    local/sbs_format_phnlm.sh $L\
	| tee data/$L/format_lm.log || exit 1;
done
wait

# Make MFCC features.
for L in $SBS_LANGUAGES; do
  mfccdir=mfcc/$L
  for x in train eval; do
    ( 
      steps/make_mfcc.sh --nj 4 --cmd "$train_cmd" data/$L/$x \
	exp/$L/make_mfcc/$x $mfccdir;
      steps/compute_cmvn_stats.sh data/$L/$x exp/$L/make_mfcc/$x $mfccdir; 
    ) &
  done
done
wait;

# Training monophone models
for L in $SBS_LANGUAGES; do
  mkdir -p exp/$L/mono;
  steps/train_mono.sh --nj 8 --cmd "$train_cmd" \
    data/$L/train data/$L/lang exp/$L/mono | tee exp/$L/mono/train.log &
done
wait;

# Training/decoding monophone models
for L in $SBS_LANGUAGES; do
      graph_dir=exp/$L/mono/graph
      mkdir -p $graph_dir
	utils/mkgraph.sh --mono data/$L/lang_test exp/$L/mono \
	$graph_dir >& $graph_dir/mkgraph.log

      	steps/decode.sh --nj 4 --cmd "$decode_cmd" --verbose 2 --acwt 0.25 --scoring-opts "--min-lmwt 3 --max-lmwt 20" $graph_dir data/$L/eval \
		exp/$L/mono/decode_eval
done


# Training/decoding triphone models
for L in $SBS_LANGUAGES; do
  (
    mkdir -p exp/$L/mono_ali
    steps/align_si.sh --nj 8 --cmd "$train_cmd" \
      data/$L/train data/$L/lang exp/$L/mono exp/$L/mono_ali \
      | tee exp/$L/mono_ali/align.log 

    mkdir -p exp/$L/tri1
	steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $NUMLEAVES $NUMGAUSSIANS \
	data/$L/train data/$L/lang exp/$L/mono_ali exp/$L/tri1 | tee exp/$L/tri1/train.log || exit 1;

    ) &
done
wait;

# Training triphone models with MFCC+deltas+double-deltas
for L in $SBS_LANGUAGES; do
      graph_dir=exp/$L/tri1/graph
      mkdir -p $graph_dir
      
	utils/mkgraph.sh data/$L/lang_test exp/$L/tri1 $graph_dir \
	>& $graph_dir/mkgraph.log 

      steps/decode.sh --nj 4 --cmd "$decode_cmd"  --verbose 2 --acwt 0.25 --scoring-opts "--min-lmwt 3 --max-lmwt 20" $graph_dir data/$L/eval \
	exp/$L/tri1/decode_eval
done

for L in $SBS_LANGUAGES; do
  (
    mkdir -p exp/$L/tri1_ali
    steps/align_si.sh --nj 8 --cmd "$train_cmd" \
      data/$L/train data/$L/lang exp/$L/tri1 exp/$L/tri1_ali \
      | tee exp/$L/tri1_ali/align.log 

    #mkdir -p exp/$L/tri2
	#steps/train_deltas.sh --cmd "$train_cmd" $NUMLEAVES $NUMGAUSSIANS \
	#data/$L/train data/$L/lang exp/$L/tri1_ali exp/$L/tri2a || exit 1;

    ) &
done
wait;

#for L in $SBS_LANGUAGES; do
      #graph_dir=exp/$L/tri2a/graph
      #mkdir -p $graph_dir
      
	  #utils/mkgraph.sh data/$L/lang_test exp/$L/tri2a $graph_dir \
	#>& $graph_dir/mkgraph.log 

      #steps/decode.sh --nj 4 --cmd "$decode_cmd" $graph_dir data/$L/eval \
	#exp/$L/tri2a/decode_eval
#done

# Train with LDA+MLLT transforms
for L in $SBS_LANGUAGES; do
  (
	mkdir -p exp/$L/tri2b
	steps/train_lda_mllt.sh --cmd "$train_cmd" \
	--splice-opts "--left-context=3 --right-context=3" $NUMLEAVES $NUMGAUSSIANS \
	data/$L/train data/$L/lang exp/$L/tri1_ali exp/$L/tri2b || exit 1;

    ) &
done
wait;

for L in $SBS_LANGUAGES; do
      graph_dir=exp/$L/tri2b/graph
      mkdir -p $graph_dir
      
	  utils/mkgraph.sh data/$L/lang_test exp/$L/tri2b $graph_dir \
	>& $graph_dir/mkgraph.log 

      steps/decode.sh --nj 4 --cmd "$decode_cmd" --verbose 2 --acwt 0.25 --scoring-opts "--min-lmwt 3 --max-lmwt 20" $graph_dir data/$L/eval \
	exp/$L/tri2b/decode_eval
done

# Training SAT+LDA+MLLT triphone systems
for L in $SBS_LANGUAGES; do
  (
    mkdir -p exp/$L/tri2b_ali
	
	steps/align_si.sh --nj 8 --cmd "$train_cmd" --use-graphs true \
		data/$L/train data/$L/lang exp/$L/tri2b exp/$L/tri2b_ali \
		| tee exp/$L/tri2b_ali/align.log 
	
	steps/train_sat.sh --cmd "$train_cmd" $NUMLEAVES $NUMGAUSSIANS \
		data/$L/train data/$L/lang exp/$L/tri2b exp/$L/tri3b || exit 1;
  ) &
done
wait;

for L in $SBS_LANGUAGES; do
      graph_dir=exp/$L/tri3b/graph
      mkdir -p $graph_dir
	  utils/mkgraph.sh data/$L/lang_test exp/$L/tri3b $graph_dir \
	>& $graph_dir/mkgraph.log

      steps/decode_fmllr.sh --nj 4 --cmd "$decode_cmd" --verbose 2 --acwt 0.25 --scoring-opts "--min-lmwt 3 --max-lmwt 20" $graph_dir data/$L/eval \
	exp/$L/tri3b/decode_eval
done

mydir=/export/ws15-pt-data/amitdas/exp_dutch
expid=$(echo `date`|sed 's/:/_/g'|awk '{print $3"_"$4}')
thisexpdir=$mydir/$expid
mkdir -p $thisexpdir/exp $thisexpdir/data
mv exp/$L $thisexpdir/exp
mv data/$L $thisexpdir/data
echo "Results for iteration $ii saved in $thisexpdir"
done

# Getting PER numbers
# for x in exp/*/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
