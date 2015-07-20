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
use Encode qw(encode decode);

die "$usage" unless(@ARGV >= 1);
my ($acro, $in_trans, $keep_rmn, $uppercase, $sil, $tagdict);
$sil="sil";
my $l2tag="<EN>";
my %L2DICT = ();
my $l2flag = 0;
GetOptions ("a" => \$acro,         # put - between letters of acronyms
            "r" => \$keep_rmn,     # keep words in GlobalPhone-style ASCII (rmn)
	        "u" => \$uppercase,    # convert words to uppercase
            "i=s" => \$in_trans,   # Input transcription
            "sil=s" => \$sil,	   # silence symbol            
			"l2tag=s" => \$l2tag,  # do not normalize text from other languages - just tag them using $l2tag. E.g. <$l2tag> some l2 text <$l2tag>
			"tagdict=s" => \$tagdict);  # if a word in transcript is part of this dictionry, then tag it as an L2 word. E.g. <$l2tag> word in dict <$l2tag>
			
binmode(STDOUT, ":encoding(UTF-8)") unless (defined($keep_rmn));
#binmode(STDOUT, ":encoding(UTF-8)");
# Populate the dictionary of tag words in a hash table
if (defined($tagdict)) {
	open(L2DICTF,'<:encoding(UTF-8)', $tagdict) || die "Unable to read from $tagdict: $!";
	foreach my $line (<L2DICTF>) {
		(($line =~ /^\;/) || ($line =~ /^\s+$/)) && next;	
		my(@recs) = split(/\s+/,$line);
		my $wrd = $recs[0];
		my $phones =  "@recs[1..$#recs]";
		#print "line-> $recs[0..$#recs]\n";
		if (!defined $L2DICT{$wrd}) {
			#$TRANSFORM{$recs[0]} = $recs[1];
			$L2DICT{$wrd} = $phones;
		}			
	}
	close (L2DICTF);
}

# Process the raw transcription
#open(T, "<$in_trans") or die "Cannot open transcription file '$in_trans': $!";
open(T, '<:encoding(UTF-8)', $in_trans) or die "Cannot open transcription file '$in_trans': $!";

while (<T>) {
  s/\r//g;  # Since files may have CRLF line-breaks!
  s/\$//g;  # Some letters & acronyms written with $, e.g $A
  chomp;
  $_ =~ m:^(\S+)\s+(.+): || die "Bad line: $_";
  my $utt_id = $1;
  my $trans = $2;

  #print "uttid = $utt_id, trans = $trans\n";
  $trans =~ s/^\s*//; $trans =~ s/\s*$//;  # Normalize spaces
  $trans =~ s/ \,(.*?)\'/ $1/g;  # Remove quotation marks.
  $trans =~ s/ \-/ /g;  # conjoined noun markers, don't need them.
  $trans =~ s/\- / /g;  # conjoined noun markers, don't need them.   
  #$trans = &rmn2utf8_GE($trans) unless (defined($keep_rmn));
  
  my $i = 0;
  my @words = split(/\s+/, $trans);
  my $nwords = @words - 1; # so that $i = 0 ... index of last word  
  print $utt_id;
  #print " $sil ";
  for my $word (@words) {
	    
	    #print " $word -> ";
		$word =~ s/[-,:\/]/ /g;       # remove commas, colons, forward slash
		$word =~ s/[\.\?]/ $sil /g;  # replace periods and question-marks by silence    
		$word =~ s/^\s*['"]/ /g;     # remove single quotes at the beginning of word, don't need them.
		$word =~ s/['"]\s*$/ /g;     # remove single quotes at the end of word, don't need them.
		$word =~ s/'//g;             # remove single quotes in between of words, don't need them.    
	  	
	    if ( $word =~ /$l2tag/ && $l2flag == 0 ) { # word is the opening <L2TAG>. This marks the beginning of L2 text.
			$l2flag = 1;						
		}		
		
		if ($l2flag !~ 1) { # if this word is not inside <L2TAG> ... <L2TAG>  
			# Distinguish acronyms before capitalizing everything, since they have 
			# different pronunciations. This may not be important.
			# print " $word -> ";			
			
			# Remove partially spoken words at the beginning or end of file
			if ($i == 0) {
				$word =~ s/^-.*/ /g;
			} elsif ($i == $nwords) {
				$word =~ s/.*-$/ /g;
			}
			if (defined($acro)) {
			  if ($word =~ /^[\p{Lu}-]+(\-.*)*$/) {
			my @subwords = split('-', $word);
			$word = "";
			for my $i (0..$#subwords) {
			  if($subwords[$i] =~ /^[\p{Lu}]{2,}$/) {
				$subwords[$i] = join('-', split(//, $subwords[$i]));
			  }
			}
			$word = join('-', @subwords);
			  }
			}
					
			if (defined($uppercase)) {
				$word = uc($word);
			} else {
				$word = lc($word);
			}			
		} 
		
    $i++;    
		
    
		if (defined $L2DICT{$word}) {
			print " $l2tag $L2DICT{$word} $l2tag";
		} else {
			print " $word";
		}
		
		if ($word =~ /$l2tag/ && $l2flag == 1) {
			$l2flag = 0;
		}
  }
  #print " $sil ";
  print "\n";
}



sub rmn2utf8_GE {
  my ($in_str) = "@_";
  
  $in_str =~ s/\~A/\x{00C4}/g;
  $in_str =~ s/\~O/\x{00D6}/g;
  $in_str =~ s/\~U/\x{00DC}/g;
  
  $in_str =~ s/\~a/\x{00E4}/g;
  $in_str =~ s/\~o/\x{00F6}/g;
  $in_str =~ s/\~u/\x{00FC}/g;
  $in_str =~ s/\~s/\x{00DF}/g;

  return NFC($in_str);  # recompose & reorder canonically
}
