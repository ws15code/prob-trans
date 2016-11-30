#!/usr/bin/perl
#
# Apache 2.0
# Preethi Jyothi (pjyothi@illinois.edu)
#
# Creates an FST that removes word position markers from phones 


if($#ARGV != 3) {
	die "Usage: <arg1: ilabels symbol file of X in text> <arg2: original phones.txt in src language > <arg3: output FST that strips markers> <arg4: output ilabels of the new FST>";
}

$olabelfile = $ARGV[0];
$originalphns = $ARGV[1];
$fstfile = $ARGV[2];
$ilabelfile = $ARGV[3];

open(OLBL, $olabelfile) or die "Cannot open file $olabelfile\n";
open(ORIGPHNS, $originalphns) or die "Cannot open file $originalphns\n";
open(FST, ">$fstfile") or die "Cannot open file $fstfile\n";
open(ILBL, ">$ilabelfile") or die "Cannot open file $ilabelfile\n";

# X -> no _marker, S, B, I, E 

@allowed_combinations = (
	'XXX', 'XXS', 'XXB', 'XSX', 'XSS', 'XSB', 'XBI', 'XBE',
	'SXX', 'SXS', 'SXB', 'SSX', 'SSS', 'SSB', 'SBI', 'SBE',
	'BII', 'BIE', 'BEX', 'BES', 'BEB', 
	'III', 'IIE', 'IEX', 'IES', 'IEB',
	'EXX', 'EXS', 'EXB', 'ESX', 'ESS', 'ESB', 'EBI', 'EBE',
);

%origphns = ();
while(<ORIGPHNS>) {
	chomp;
	next if $_ =~ /#/;
	($phn, $index) = split(/\s+/);
	$origphns{$phn} = $index;
}
close(ORIGPHNS);

%ilabels = ();

print ILBL "ilabels "; #needs to be in archive format
$ilabelcnt = 0;
while(<OLBL>) {
	chomp;
	($triphn, $index) = split(/\s+/);
	if ($triphn =~ /\//) {
		($phn1,$phn2,$phn3) = split(/\//,$triphn);
		foreach $comb (@allowed_combinations) {
			($m1,$m2,$m3) = split(//,$comb);
			$mp1 = addmark($phn1,$m1);
			$mp2 = addmark($phn2,$m2);
			$mp3 = addmark($phn3,$m3);
			if ( exists $origphns{$mp1} && exists $origphns{$mp2} && exists $origphns{$mp3} ) {
				$mtriphn = "$mp1/$mp2/$mp3";
				if (!exists $ilabels{$mtriphn}) {
					$ilabels{$mtriphn} = $ilabelcnt;
					$indtriphn = "$origphns{$mp1} $origphns{$mp2} $origphns{$mp3} ;";
					print ILBL "$indtriphn";
					$ilabelcnt++;
				}
				print FST "0\t0\t$ilabels{$mtriphn}\t$index\n";
			}
		}
	} else { # disambig, <eps>
		if (!exists $ilabels{$triphn}) {
			$ilabels{$triphn} = $ilabelcnt;
			if($triphn =~ /eps/) {
				print ILBL " ;";
			} elsif(exists $origphns{$triphn}) {
				print ILBL "$origphns{$triphn} ;"; 
			} else {
				print ILBL "-1 ;";
			}
			$ilabelcnt++;
		}
		print FST "0\t0\t$ilabels{$triphn}\t$index\n";
	}
}
print FST "0\n";
print ILBL "\n";

close(OLBL);
close(ILBL);

sub addmark {
    my ($phn,$mark) = @_;
	if ($mark eq "X") {
		return $phn;
	}
	return "$phn"."_"."$mark";
}


