#default settings for steps/nnet/{pretrain_dbn.sh, train.sh}
skip_cuda_check=false 
my_use_gpu=yes
corpus_dir=/media/data/workspace/corpus

#host dependendent settings 
if [ `hostname` = "ifp-48" ]; then
	export KALDI_ROOT=/ws/ifp-48_1/hasegawa/amitdas/gold/kaldi/kaldi-trunk
	corpus_dir=/ws/rz-cl-2/hasegawa/amitdas/corpus	
elif [ `hostname` = "ifp-30" ]; then
	export KALDI_ROOT=/media/data/workspace/gold/kaldi/kaldi-trunk	
	skip_cuda_check=true
	my_use_gpu=no
elif [ `hostname` = "pac" ]; then
	export KALDI_ROOT=/media/data/workspace/gold/kaldi/kaldi-trunk	
else
	echo "Unidentified hostname `hostname`"; exit 1;
fi

export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/nnet2bin/:$KALDI_ROOT/src/kwsbin:$KALDI_ROOT/src/online2bin/:$KALDI_ROOT/src/ivectorbin/:$KALDI_ROOT/src/lmbin/:$PWD:$PATH
export LC_ALL=C
export IRSTLM=$KALDI_ROOT/tools/irstlm
