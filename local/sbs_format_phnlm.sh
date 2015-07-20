#!/bin/bash -u

# Generating a phone bigram LM

set -o errexit
set -o pipefail

function read_dirname () {
  local dir_name=`expr "X$1" : '[^=]*=\(.*\)'`;
  [ -d "$dir_name" ] || { echo "Argument '$dir_name' not a directory" >&2; \
    exit 1; }
  local retval=`cd $dir_name 2>/dev/null && pwd || exit 1`
  echo $retval
}

PROG=`basename $0`;
usage="Usage: $PROG <2-letter language code>\n
Prepare phone bigram LM for an SBS language.\n\n
";

if [ $# -lt 1 ]; then
  echo -e $usage; exit 1;
fi

while [ $# -gt 0 ];
do
  case "$1" in
  --help) echo -e $usage; exit 0 ;;
  ??) LCODE=$1; shift ;;
  *)  echo "Unknown argument: $1, exiting"; echo -e $usage; exit 1 ;;
  esac
done

[ -f path.sh ] && . path.sh  # Sets the PATH to contain necessary executables, incl. IRSTLM

srcdir=data/${LCODE}/local/data
lmdir=data/${LCODE}/local/lm
tmpdir=data/${LCODE}/local/lm_tmp

mkdir -p $lmdir $tmpdir

echo "Preparing phone LMs..."

  [ -z "$IRSTLM" ] && \
    echo "LM building won't work without setting the IRSTLM env variable" && exit 1;
  ! which build-lm.sh 2>/dev/null  && \
    echo "IRSTLM does not seem to be installed (build-lm.sh not on your path): " && \
    echo "go to <kaldi-root>/tools and try 'make irstlm_tgt'" && exit 1;

	cut -f2- $srcdir/train_text | sed -e 's:^:<s> :' -e 's:$: </s>:' \
	> $srcdir/lm_train.text
	build-lm.sh -i $srcdir/lm_train.text -n 2 -o $tmpdir/lm_phone.gz

  ! which compile-lm 2>/dev/null  && \
    echo "IRSTLM does not seem to be installed (compile-lm not on your path): " && exit 1;

	# unk creates an epsilon self-loop which makes G non-determinizable 
  #compile-lm $tmpdir/lm_phone.gz -t=yes /dev/stdout | \
	#grep -v unk | gzip -c > $lmdir/lm_phone.arpa.gz
  compile-lm $tmpdir/lm_phone.gz -t=yes /dev/stdout | \
	 gzip -c > $lmdir/lm_phone.arpa.gz

echo "Done."

echo "Preparing the language model G acceptor"

test=data/${LCODE}/lang_test
mkdir -p $test
cp -r data/${LCODE}/lang/* $test

gunzip -c $lmdir/lm_phone.arpa.gz | \
    egrep -v '<s> <s>|</s> <s>|</s> </s>' | \
    arpa2fst - | fstprint | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$test/words.txt \
     --osymbols=$test/words.txt  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > $test/G.fst
 
fstisstochastic $test/G.fst
 # The output is like:
 # 9.14233e-05 -0.259833
 # we do expect the first of these 2 numbers to be close to zero (the second is
 # nonzero because the backoff weights make the states sum to >1).
 # Because of the <s> fiasco for these particular LMs, the first number is not
 # as close to zero as it could be.

#If the script is exitting after running utils/validate_lang.pl, and the error script states that the fst is not able to be determinized. Try removing the "unk" symbol

utils/validate_lang.pl data/${LCODE}/lang_test > $lmdir/train_val.log 2>&1

echo "Done preparing G."

rm -r $tmpdir
