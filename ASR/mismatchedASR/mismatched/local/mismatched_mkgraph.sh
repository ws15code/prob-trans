#!/bin/bash

# Adapted from Kaldi scripts. Please see COPYING for more details.

# Apache 2.0

# This script creates a fully expanded decoding graph (HCLG) that represents
# all the language-model, pronunciation dictionary (lexicon), context-dependency,
# and HMM structure in our model.  The output is a Finite State Transducer
# that has word-ids on the output, and pdf-ids on the input (these are indexes
# that resolve to Gaussian Mixture Models).  
# See
#  http://kaldi.sourceforge.net/graph_recipe_test.html
# (this is compiled from this repository using Doxygen,
# the source for this part is in src/doc/graph_recipe_test.dox)


N=3
P=1
reverse=false
if [ -f path.sh ]; then . ./path.sh; fi

for x in `seq 2`; do 
  [ "$1" == "--mono" ] && N=1 && P=0 && shift;
  [ "$1" == "--quinphone" ] && N=5 && P=2 && shift;
  [ "$1" == "--reverse" ] && reverse=true && shift;
done

if [ $# -ne 1 ]; then
   echo "Usage: $0 [options] <settings file>"
   echo " Options:"
   echo " --mono          #  For monophone models."
   echo " --quinphone     #  For models with 5-phone context (3 is default)"
   exit 1;
fi

. $1 #source the settings file

langtestdir=$datadir/$tgtlangtest
tree=$expdir/tree
model=$expdir/final.mdl
tgt2src=$edir/$tgtxsrcmap
dir=$expdir/$tgtgraphdir

mkdir -p $dir

tscale=1.0
loopscale=0.1

# If $langtestdir/tmp/LG.fst does not exist or is older than its sources, make it...
# (note: the [[ ]] brackets make the || type operators work (inside [ ], we
# would have to use -o instead),  -f means file exists, and -ot means older than).

required="$langtestdir/L.fst $langtestdir/G.fst $langtestdir/phones.txt $langtestdir/words.txt $langtestdir/phones/silence.csl $langtestdir/phones/disambig.int $model $tree $tgt2src"
for f in $required; do
  [ ! -f $f ] && echo "mkgraph.sh: expected $f to exist" && exit 1;
done

mkdir -p $langtestdir/tmp
# Note: [[ ]] is like [ ] but enables certain extra constructs, e.g. || in 
# place of -o
if [[ ! -s $langtestdir/tmp/LG.fst || $langtestdir/tmp/LG.fst -ot $langtestdir/G.fst || \
      $langtestdir/tmp/LG.fst -ot $langtestdir/L_disambig.fst ]]; then
  fsttablecompose $langtestdir/L_disambig.fst $langtestdir/G.fst | fstdeterminizestar --use-log=true | \
    fstminimizeencoded  > $langtestdir/tmp/LG.fst || exit 1;
  fstisstochastic $langtestdir/tmp/LG.fst || echo "[info]: LGa not stochastic."
fi

clg=$langtestdir/tmp/CLG_${N}_${P}.fst

if [[ ! -s $clg || $clg -ot $langtestdir/tmp/LG.fst ]]; then
  fstcomposecontext --context-size=$N --central-position=$P \
   --read-disambig-syms=$langtestdir/phones/disambig.int \
   --write-disambig-syms=$langtestdir/tmp/disambig_ilabels_${N}_${P}.int \
    $langtestdir/tmp/ilabels_${N}_${P} < $langtestdir/tmp/LG.fst >$clg
  fstisstochastic $clg  || echo "[info]: CLG not stochastic."
fi

if [[ ! -s $clg || $clg -ot $langtestdir/tmp/LG.fst ]]; then
   fstmakecontextsyms $langtestdir/phones.txt $langtestdir/tmp/ilabels_${N}_${P} > $langtestdir/tmp/C_ilabels.txt
   ./local/mismatched_mkxfst.sh $1 $langtestdir/tmp/C_ilabels.txt 
fi

xclg=$langtestdir/tmp/XCLG.fst
xfst=$xdir/X.fst
wilabels=$xdir/W_ilabels.sym
wfst=$xdir/W.fst

if [[ ! -s $xclg || $xclg -ot $clg ]]; then
  fstarcsort --sort_type=olabel $xfst | fstcompose - $clg | fstdeterminizestar --use-log=true | \
     fstminimizeencoded > $xclg || exit 1;
fi

if [[ ! -s $dir/Ha.fst || $dir/Ha.fst -ot $model  \
    || $dir/Ha.fst -ot $langtestdir/tmp/ilabels_${N}_${P} ]]; then
  if $reverse; then
    make-h-transducer --reverse=true --push_weights=true \
      --disambig-syms-out=$dir/disambig_tid.int \
      --transition-scale=$tscale $wilabels $tree $model \
      > $dir/Ha.fst  || exit 1;
  else
    make-h-transducer --disambig-syms-out=$dir/disambig_tid.int \
      --transition-scale=$tscale $wilabels $tree $model \
       > $dir/Ha.fst  || exit 1;
  fi
  fstarcsort --sort_type=ilabel $dir/Ha.fst | fstcompose - $wfst > $dir/HaW.fst
fi

if [[ ! -s $dir/HWXCLGa.fst || $dir/HWXCLGa.fst -ot $dir/HaW.fst || \
      $dir/HWXCLGa.fst -ot $cxlg ]]; then
  fstarcsort --sort_type=olabel $dir/HaW.fst | fsttablecompose - $xclg | \
     fstrmsymbols $dir/disambig_tid.int | fstrmepslocal | \
     fstminimizeencoded > $dir/HWXCLGa.fst || exit 1;
  fstisstochastic $dir/HWXCLGa.fst || echo "HWXCLGa is not stochastic"
fi

if [[ ! -s $dir/HWXCLGa.fst || $dir/HWXCLG.fst -ot $dir/HWXCLGa.fst ]]; then
  add-self-loops --self-loop-scale=$loopscale --reorder=true \
    $model < $dir/HWXCLGa.fst > $dir/HCLG.fst || exit 1;

  if [ $tscale == 1.0 -a $loopscale == 1.0 ]; then
    # No point doing this test if transition-scale not 1, as it is bound to fail. 
    fstisstochastic $dir/HCLG.fst || echo "[info]: final HWXCLG is not stochastic."
  fi
fi

cp $langtestdir/words.txt $dir/ || exit 1;
mkdir -p $dir/phones
cp $langtestdir/phones/word_boundary.* $dir/phones/ 2>/dev/null # might be needed for ctm scoring,
cp $langtestdir/phones/align_lexicon.* $dir/phones/ 2>/dev/null # might be needed for ctm scoring,
  # but ignore the error if it's not there.

cp $langtestdir/phones/disambig.{txt,int} $dir/phones/ 2> /dev/null
cp $langtestdir/phones/silence.csl $dir/phones/ || exit 1;
cp $langtestdir/phones.txt $dir/ 2> /dev/null # ignore the error if it's not there.

echo "Successfully created the decoding graph!"
