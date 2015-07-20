#!/bin/bash

#sbs_create_phntrans_UR.sh
#usage: scriptname.sh listOfUtteranceIDs g2pDict transcriptDir

LISTOFUTTID=$1
PHONEDICT=$2
DATADIR=$3

#Create the Phonemic transcriptions
python ./local/sbs_create_phntrans_UR.py $LISTOFUTTID $PHONEDICT $DATADIR
