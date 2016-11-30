#!/usr/bin/perl
#

# Create FST mapping triphones in the target language
# to triphones in the source language, using a monophone
# map file.
#

if($#ARGV != 2) {
	print "Usage: script <arg1: monophone tgtxsrc map file> <arg2: triphone list in target language> <arg3: output phones.txt for input of new FST>\n";
	exit(0);
}

open(TGTSRC, $ARGV[0]) or die "Cannot open file $ARGV[0]\n";
open(TRTGT, $ARGV[1]) or die "cannot open file $ARGV[1]\n";
open(PHNOUT, ">$ARGV[2]") or die "Cannot open file $ARGV[2]\n";

%tgt2src_map = ();
# TGTSRC is of the form:
# aa1 AA,0.5;AA0,0.5
# ae1 EY,1.0
# and so on.
while(<TGTSRC>) {
	chomp;
	($tphn, $srcphns) = split(/\s+/);
	$tgt2src_map{$tphn} = $srcphns;
}
close(TGTSRC);

%src_triphnlist = ();
$newindex = 0;
while(<TRTGT>) {
	chomp;
	($triphn, $index) = split(/\s+/);
	if ($triphn =~ /\//) { #triphone
		($phn1,$phn2,$phn3) = split(/\//,$triphn);
		$src1 = $tgt2src_map{$phn1};
		$src2 = $tgt2src_map{$phn2};
		$src3 = $tgt2src_map{$phn3};
		if (!defined $src1 || !defined $src2 || !defined $src3) {
			die "Incomplete tgt-src mapping: either $phn1,$phn2 or $phn3 not mapped";
		}
		$src1 =~ s/\s//g; $src2 =~ s/\s//g; $src3 =~ s/\s//g;
		@entries1 = split(/;/, $src1); @entries2 = split(/;/, $src2); @entries3 = split(/;/, $src3);
		foreach $e1 (@entries1) {
			foreach $e2 (@entries2) {
				foreach $e3 (@entries3) {
					($srcphn1, $prob1) = split(/,/,$e1);
					($srcphn2, $prob2) = split(/,/,$e2);
					($srcphn3, $prob3) = split(/,/,$e3);
					$srctphn = "$srcphn1/$srcphn2/$srcphn3";
					$totalprob = $prob1 * $prob2 * $prob3; 
					if($totalprob > 1 || $totalprob <= 0) {
						die "Illegal probability value: $totalprob";
					}
					$totalscore = -log($totalprob);
					if(!exists $src_triphnlist{$srctphn}) {
						$src_triphnlist{$srctphn}++;
						print PHNOUT "$srctphn $newindex\n";
						print "0\t0\t$srctphn\t$triphn\t$totalscore\n";
						$newindex++;
					}
				}
			}
		}
	} else {
		if($triphn =~ /eps/) {
			print PHNOUT "$triphn $newindex\n";
			$src = $tgt2src_map{$triphn};
			($srcphn, $prob) = split(/,/,$src);
			$score = -log($prob);
			#print "0\t0\t$triphn\t$srcphn\t$score\n";
			$newindex++;
		} elsif($triphn =~ /#/) {
			print PHNOUT "$triphn $newindex\n";
			print "0\t0\t$triphn\t$triphn\n";
			$newindex++;
		}
	}
}

close(TRTGT);
print "0\n";
