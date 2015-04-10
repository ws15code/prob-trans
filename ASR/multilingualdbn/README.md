# multilingualdbn
multilingual dbn

DBN trained on multilingual SBS data can be found in:
exp/dnn4_pretrain-dbn/6.dbn (binary)
exp/dnn4_pretrain-dbn/6.dbn.txt.gz (ascii gzipped)

Multilingual SBS data:
Total data: approx 20 hours
Number of languages: 70
Data per language: about 17 minutes

DBN config:
input visible layer: 429 dim ( [39 MFCC + delta + delta^2 ] * 11 spliced )
hidden layers: 6 layers, 1024 nodes per layer (no bottleneck layer)
