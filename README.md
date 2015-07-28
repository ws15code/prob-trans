# prob-trans
scripts to train and test SBS speech recognizers.

Usage:
```
git clone https://github.com/kaldi-asr/kaldi;
cd kaldi/egs;
git clone https://github.com/ws15code/prob-trans.git --branch kaldi-scripts --single-branch;
cd prob-trans;
ln -s ../wsj/s5/steps steps;
ln -s ../wsj/s5/utils utils;
qsub -cwd ./run.sh;
```
