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
if [ $# -ne 2 ]; then
	echo "Usage: $0 <settings file> <C ilabels file, in text format>"
	exit 1;
fi

. $1 #source the settings file

# INITIALIZATIONS

mkdir -p $xdir

tmpdir=/tmp/$$.dir

tgtxsrcmap=$edir/$tgtxsrcmap
tgtilabels=$2

required="$tgtxsrcmap $tgtilabels"
for f in $required; do
  [ ! -f $f ] && echo "$0: expected $f to exist" && exit 1;
done

mkdir -p $tmpdir

# Create tgt2src FST -- call it X
# This will be composed with CLG of the target language; XCLG will map 
# triphones (w/o word markers) in the src language to words in the target language
echo "Creating the cross-lingual X fst"
perl local/create_xlingual_mapfst.pl $tgtxsrcmap $tgtilabels $xdir/X_in_vocab.txt > $xdir/X.fst.txt
fstcompile --isymbols=$xdir/X_in_vocab.txt --osymbols=$tgtilabels $xdir/X.fst.txt > $xdir/X.fst

# Create a new FST, W, that maps context-phones with word position markers to context-phones without the markers
perl local/create_wrdmarker_fst.pl $xdir/X_in_vocab.txt $srcdir/data/lang/phones.txt $xdir/W.fst.txt $xdir/W_ilabels.txt
fstcompile $xdir/W.fst.txt > $xdir/W.fst
copy-ilabels ark,t:$xdir/W_ilabels.txt $xdir/W_ilabels.sym

rm -rf $tmpdir

echo "Mismatched FST successfully prepared"

exit 0
