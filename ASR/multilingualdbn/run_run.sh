#! /bin/bash

bash run.sh 1 # data prep
bash run.sh 2 # feat gen
bash run.sh --cmvn-optsf ../../turkish/s5_p_v2/exp/mono/cmvn_opts 3 # rbm pretrain

