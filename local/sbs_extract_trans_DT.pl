#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter

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


# This script normalizes the GlobalPhone German transcripts encoded in 
# GlobalPhone style ASCII (rmn) that have been extracted in a format where each 
# line contains an utterance ID followed by the transcript, e.g:
# GE008_10 man mag es drehen und wenden wie man will
# The normalization is similar to that in 'gp_norm_dict_GE.pl' script.

my $usage = "Usage: $0 [-a|-r|-u] -i transcript > formatted\
Normalizes transcriptions for Dutch. The input format is assumed\
to be utterance ID followed by transcript on the same line.\
Options:\
  -a\tTreat acronyms differently (puts - between individual letters)\
  -r\tKeep words in GlobalPhone-style ASCII (convert to UTF8 by default)\
  -u\tConvert words to uppercase (by default make everything lowercase)\n";
  
use strict;
use Getopt::Long;
use Unicode::Normalize;
use File::Basename;
use File::Path qw/make_path/;
 
my ($rawtransdir, $rawtransextn);
$rawtransdir="/export/ws15-pt-data/data/transcripts/matched/dutch";
$rawtransextn="txt";
#$rawtransscp="local/tmp/DT/DT_rawtrans.trans1"; 

die "$usage" unless(@ARGV >= 1);
GetOptions ("d=s" => \$rawtransdir,        # directory of raw transcription files
            "e=s" => \$rawtransextn);     # extension of raw transcription files

my ($utt_idf) = @ARGV;   

open(UIDF, "<$utt_idf") or die "Cannot open utt id file list '$utt_idf': $!";
my @utt_ids=<UIDF>;
close (UIDF);

#make_path(dirname($rawtransscp));
#system("rm $rawtransscp 2>/dev/null");
#open(RAWTRANS, '>>', "$rawtransscp") or die "Cannot write to raw trans file '$rawtransscp': $!";

foreach my $utt_id (@utt_ids) {
	chomp $utt_id;	
	my $in_trans=$rawtransdir."/".$utt_id.".".$rawtransextn;	
	open(T, "<$in_trans") or die "Cannot open transcription file '$in_trans': $!";
	my @trans=<T>;
	close(T);
	chomp @trans;
	#print RAWTRANS "$utt_id\t @trans\n";
	print "$utt_id\t @trans\n";
}
#close (RAWTRANS);
#print "Done extracting raw transcription scp file: $rawtransscp\n";


