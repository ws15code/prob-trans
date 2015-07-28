#!/bin/bash -u

# Copyright 2012  Arnab Ghoshal

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

set -o errexit

function error_exit () {
  printf "$@\n" >&2; exit 1;
}

function read_dirname () {
  [ -d "$1" ] || error_exit "Argument '$1' not a directory";
  local retval=`cd $1 2>/dev/null && pwd || exit 1`
  echo $retval
}

. ./path.sh    # Sets the PATH to contain necessary executables

# Begin configuration section.
config_dir=conf    #
# end configuration sections

PROG=`basename $0`;
help_message="Usage: "`basename $0`" [options] LC [LC ... ]
where LC is a 2-letter code for SBS languages (e.g. MD for Mandarin).\n
options: 
  --help                # print this message and exit
  --config-dir DIR      # directory to find config files (default: $config_dir)
";

. utils/parse_options.sh

if [ $# -lt 1 ]; then
  printf "$help_message\n"; exit 1;
fi

#CORPUS=$1; shift;
LANGUAGES=
while [ $# -gt 0 ]; do
  case "$1" in
  ??) LANGUAGES=$LANGUAGES" $1"; shift ;;
  *)  echo "Unknown argument: $1, exiting"; error_exit "$help_message" ;;
  esac
done

[ -f path.sh ] && . path.sh  # Sets the PATH to contain necessary executables
SIL=sil

# Set local to UTF-8
#export LC_ALL=en_US.UTF-8

# (1) Create the dictionary
for L in $LANGUAGES; do
  srcdir=data/$L/local/data
  printf "Language - ${L}: preparing pronunciation lexicon ... "
  mkdir -p data/$L/local/dict
  full_name=`awk '/'$L'/ {print $2}' $config_dir/lang_codes.txt`;
  phones=$config_dir/$full_name/phones.txt
  cut -f2- $srcdir/train_text | tr ' ' '\n' | sort -u | perl -n -e 'if($_ !~ /^\s*$/) { print "$_"; }' | grep -v sil | sed -e 's/
  #cat $srcdir/train_text | ruby -e 'STDIN.each{|x| y=x.split(/ +/); if y.length>1 then z=y[2..-1].join("\n"); end; puts z;}' | sort -u > $phones

  awk '{print $1"\t"$1}' $phones > data/$L/local/dict/lexicon_nosil.txt

  (printf 'sil\tsil\n<unk>\tspn\n';) \
    | cat - data/$L/local/dict/lexicon_nosil.txt \
    > data/$L/local/dict/lexicon.txt;
  echo "Done"

  printf "Language - ${L}: extracting phone lists ... "
  # silence phones, one per line.
  { echo sil; echo spn; } > data/$L/local/dict/silence_phones.txt
  echo sil > data/$L/local/dict/optional_silence.txt
  cut -f2- data/$L/local/dict/lexicon_nosil.txt | tr ' ' '\n' | sort -u | grep -v "$SIL" \
    > data/$L/local/dict/nonsilence_phones.txt
  # Ask questions about the entire set of 'silence' and 'non-silence' phones. 
  # These augment the questions obtained automatically by clustering. 
  ( tr '\n' ' ' < data/$L/local/dict/silence_phones.txt; echo;
    tr '\n' ' ' < data/$L/local/dict/nonsilence_phones.txt; echo;
    ) > data/$L/local/dict/extra_questions.txt
  echo "Done"
done

echo "Finished dictionary preparation."