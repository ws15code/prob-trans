#! /usr/bin/perl 
#
# Convert phoneme level transcriptions in an existing phone set to a new phone set 
# amitdas@illinois.edu
# ============================================================================
# Revision History
# Date 		Author	Description of Change
# 11/27/14	ad 		Created trans2world.pl
# 02/16/15	ad		Added -map-from-col, -map-to-col, -trans_start_col, 
#					-trans_end_col to make it more generic. Renamed to transnorm.pl
#
# ============================================================================

my $usage = "Usage:\n>perl transnorm.pl [-map-from-col n1] [-map-to-col n2] [-trans_start_col m1] [-trans_end_col m2] train.trans phoneset1_to_phoneset2.map 
This script normalizes phonetic transcriptions given in train.trans, 
by mapping the existing phone set to a new phone set given in the map file 
phoneset1_to_phoneset2.map. Existing phone set is the set of phones given in 
column n1 (-map-from-col n1, default 1) and the new phone set is the set of phones 
given in column n2 (-map-to-col n2, default 2) of the map file. 
The phonetic transcription are assumed to contain phones in the columns 
from m1 (-trans_start_col m1, default 2) to 
m2 (-trans_end_col m2, default to last column) on the same line. 

Example:
>perl transnorm.pl -map-from-col 2 -map-to-col 3 -start-col-trans 2 train.trans timit2worldmap.txt 
This will convert all phones appearing from col 2 (-start-col-trans 2) 
to the last col (default value of -trans_end_col option) 
of the transcription file (train.trans) to a new set of phones.
The current phone set used in the transcription must be present in 
col 2 of the map file (-map-from-col 2) and the new phone set is taken 
from the col 3 of the map file (-map-to-col 3).\n";

#use strict;
use Getopt::Long;
die "$usage" unless(@ARGV >= 2);
my $map_from_col = 1; # default, column 1 of the map file
my $map_to_col = 2;   # default, column 2 of the map file
my $trans_start_col = 2; # default, phoneme transcriptions begin from column 2 of the transcription file
my $trans_end_col = undef; # default, phoneme transcriptions end at the last column of the transcription file
GetOptions ("map-from-col=i" => \$map_from_col, "map-to-col=i" => \$map_to_col, "trans-start-col=i" => \$trans_start_col,"trans-end-col=i" => \$trans_end_col); 


my ($transfile1, $dictxformfile) = @ARGV;

( $trans_start_col > 0 ) || die "start col of phones in $transfile1 must be positive. Current value is $trans_start_col: $!";
( $map_from_col > 0 ) || die "col from map in $dictxformfile must be positive. Current value is $map_from_col: $!";
( $map_to_col > 0 ) || die "col to map in $dictxformfile must be positive. Current value is $map_to_col: $!";
if ( defined ($trans_end_col) ) {	
( $trans_end_col >= $trans_start_col ) || die "start col of phones in $transfile1 cannot be greater than end col. Current start col=$trans_start_col, end col=$trans_end_col: $!";
}

# Read the xform file to populate the transform	in a hash
$map_from_col--;
$map_to_col--;
open(XFORM,"<$dictxformfile") || die "Unable to read from $dictxformfile: $!";
foreach $line (<XFORM>) {
	($line =~ /^\;/) && next;	
	my(@recs) = split(/\s+/,$line);
	#print "line-> $recs[0..$#recs]\n";
	if (!defined $TRANSFORM{$recs[$map_from_col]}) {
	#$TRANSFORM{$recs[0]} = $recs[1];
	$TRANSFORM{$recs[$map_from_col]} = $recs[$map_to_col];
	}					
}
#$TRANSFORM{"SIL"} = "sil";
close(XFORM);
#print "$_ $TRANSFORM{$_}\n" for sort keys %TRANSFORM;

# Apply xform to phone transcriptions, and write the xformed phonemes to stdout
$trans_start_col--;
#if ( !defined ($trans_end_col) ) { 	print "undefined\n"; } 
#else { 	print "defined\n"; }
open(TR1, "<$transfile1")   || die "Unable to read from $transfile1: $!";
while ($line = <TR1>) {	
	($line =~ /^\s+$/) && next;	
	chomp ($line);
	my(@recs) = split(/\s+/,$line);
	#print "@recs[1..$#recs]\n";
	if ( !defined ($trans_end_col) ) {
		@xphonemes = map { exists $TRANSFORM{$_} ? $TRANSFORM{$_} : () } @recs[$trans_start_col..$#recs];
		print "@recs[0..$trans_start_col-1] @xphonemes[0..$#xphonemes]\n";								
	} 
	else {		
		@xphonemes = map { exists $TRANSFORM{$_} ? $TRANSFORM{$_} : () } @recs[$trans_start_col..$trans_end_col-1];
		print "@recs[0..$trans_start_col-1] @xphonemes[0..$#xphonemes] @recs[$trans_end_col..$#recs] \n";								
	}	
}	
close(TR1);
