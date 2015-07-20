#!/bin/bash -u

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
usage="Usage: $PROG <arguments> <2-letter language code>\n
Prepare train, test file lists for an SBS language.\n\n
Required arguments:\n
  --corpus-dir=DIR\tDirectory for the SBS (matched) corpus\n
  --trans-dir=DIR\tDirectory containing the matched transcripts for all languages\n
  --list-dir=DIR\tDirectory containing the train/eval split for all languages\n
  --lang-map=FILE\tMapping from 2-letter language code to full name\n
  --eng-ipa-map=FILE\tMapping from English phones in ARPABET to IPA phones\n
  --eng-dict=FILE\tEnglish dictionary file (e.g. CMUdict)\n
";

if [ $# -lt 7 ]; then
  echo -e $usage; exit 1;
fi

while [ $# -gt 0 ];
do
  case "$1" in
  --help) echo -e $usage; exit 0 ;;
  --corpus-dir=*) 
  SBSDIR=`read_dirname $1`; shift ;;
  --trans-dir=*)
  TRANSDIR=`read_dirname $1`; shift ;;
  --list-dir=*)
  LISTDIR=`read_dirname $1`; shift ;;
  --lang-map=*)
  LANGMAP=`expr "X$1" : '[^=]*=\(.*\)'`; shift ;;
  --eng-ipa-map=*)
  ENGMAP=`expr "X$1" : '[^=]*=\(.*\)'`; shift ;;
  --eng-dict=*)
  ENGDICT=`expr "X$1" : '[^=]*=\(.*\)'`; shift ;;
  ??) LCODE=$1; shift ;;
  *)  echo "Unknown argument: $1, exiting"; echo -e $usage; exit 1 ;;
  esac
done

[ -f path.sh ] && . path.sh  # Sets the PATH to contain necessary executables

full_name=`awk '/'$LCODE'/ {print $2}' $LANGMAP`;

num_train_files=$(wc -l $LISTDIR/$full_name/train.txt | awk '{print $1}')
num_eval_files=$(wc -l $LISTDIR/$full_name/eval.txt | awk '{print $1}')

if [[ $num_train_files -eq 0 || $num_eval_files -eq 0 ]]; then
	echo "No utterances found in $LISTDIR/$full_name/train.txt OR $LISTDIR/$full_name/eval.txt" && exit 1
fi
# Checking if sox is installed
which sox > /dev/null

mkdir -p data/$LCODE/wav # directory storing all the downsampled WAV files
tmpdir=$(mktemp -d);
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p $tmpdir
mkdir -p $tmpdir/downsample
mkdir -p $tmpdir/trans

soxerr=$tmpdir/soxerr;

for x in train eval; do
	file="$LISTDIR/$full_name/$x.txt"
	mkdir -p data/$LCODE/wav/$x
	>$soxerr
	nsoxerr=0
	while read line; do
		set +e
		base=`basename $line .wav`
		wavfile="$SBSDIR/$full_name/$base.wav"		
		owavfile="data/$LCODE/wav/$x/$base.wav"
		[ -e $owavfile ] || sox $wavfile -r 8000 -t wav data/$LCODE/wav/$x/$base.wav 		
		if [ $? -ne 0 ]; then
			echo "$wavfile: exit status = $?" >> $soxerr
			let "nsoxerr+=1"
		else 
			nsamples=`soxi -s "$owavfile"`;
			if [[ "$nsamples" -gt 1000 ]]; then
				echo "$owavfile" >> $tmpdir/downsample/${x}_wav
			else
				echo "$owavfile: #samples = $nsamples" >> $soxerr;
				let "nsoxerr+=1"
			fi
		fi
		set -e
	done < "$file"

	[[ "$nsoxerr" -gt 0 ]] && \
		echo "sox: error converting following $nsoxerr file(s):" >&2
	[ -f "$soxerr" ] && cat "$soxerr" >&2

	sed -e "s:.*/::" -e 's:.wav$::' $tmpdir/downsample/${x}_wav > $tmpdir/downsample/${x}_basenames_wav	
	paste $tmpdir/downsample/${x}_basenames_wav $tmpdir/downsample/${x}_wav | sort -k1,1 > data/${LCODE}/local/data/${x}_wav.scp 
	
	# Processing transcripts 
	# first, map English words in transcripts to their IPA pronunciations
	./local/sbs_english_filter.pl --ipafile $ENGMAP --dictfile $ENGDICT --utts "$tmpdir/downsample/${x}_basenames_wav" --idir "$TRANSDIR/${full_name}" --odir $tmpdir/trans

	#################################################
	#### LANGUAGE SPECIFIC TRANSCRIPT PROCESSING ####
	# This script could take as arguments: 
	# 1. the list of utterance IDs ($tmpdir/downsample/${x}_basenames_wav)
	# 2. the grapheme to phoneme mapping for the target language (available either in the 2-column format or as an FST)
	# 3. directory containing all the matched transcripts ($TRANSDIR)
	case "$LCODE" in
		AR)
			/export/ws15-pt-data/rsloan/ar_to_ipa.sh --utts $tmpdir/downsample/${x}_basenames_wav --transdir "$TRANSDIR/${full_name}" > $tmpdir/${LCODE}_${x}.trans 
			;;
		DT)
			/export/ws15-pt-data/rsloan/dt_to_ipa.sh --utts $tmpdir/downsample/${x}_basenames_wav --transdir "$TRANSDIR/${full_name}" > $tmpdir/${LCODE}_${x}.trans
                        #./local/sbs_create_phntrans_DT.sh --g2p conf/${full_name}/g2pmap.txt --utts $tmpdir/downsample/${x}_basenames_wav --transdir $TRANSDIR/${full_name} > $tmpdir/${LCODE}_${x}.trans
			;;
		MD)
			#<g2pscript_forMandarin> > $tmpdir/${LCODE}_${x}.trans 
			;;
		HG)
			python /export/ws15-pt-data/kaldi-trunk/egs/SBS/local/sbs_create_phntrans_HG.py --g2p conf/${full_name}/g2pmap.txt --utts $tmpdir/downsample/${x}_basenames_wav --transdir "$TRANSDIR/${full_name}" > $tmpdir/${LCODE}_${x}.trans 
			;;
		SW)
			./local/sbs_create_phntrans_SW.pl --g2p conf/${full_name}/g2pmap.txt --utts $tmpdir/downsample/${x}_basenames_wav --transdir $tmpdir/trans --wordlist conf/${full_name}/wordlist.txt > $tmpdir/${LCODE}_${x}.trans
			;;
		UR)	
			./local/sbs_create_phntrans_UR.sh $tmpdir/downsample/${x}_basenames_wav conf/${full_name}/g2pmap.txt $TRANSDIR/${full_name} > $tmpdir/${LCODE}_${x}.trans
			;;
		*) 
			echo "Unknown language code $LCODE." && exit 1
	esac
	#################################################

	paste $tmpdir/downsample/${x}_basenames_wav $tmpdir/${LCODE}_${x}.trans | sort -k1,1 > data/${LCODE}/local/data/${x}_text

	sed -e 's:\-.*$::' $tmpdir/downsample/${x}_basenames_wav |   
	paste -d' ' $tmpdir/downsample/${x}_basenames_wav - | sort -t' ' -k1,1 \
	> data/${LCODE}/local/data/${x}_utt2spk
	./utils/utt2spk_to_spk2utt.pl data/${LCODE}/local/data/${x}_utt2spk > data/${LCODE}/local/data/${x}_spk2utt || exit 1;
done

