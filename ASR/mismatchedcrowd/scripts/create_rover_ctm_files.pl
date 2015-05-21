#!/usr/bin/perl
#
# Create ctm files out of Turker transcripts

if($#ARGV != 1) {
	print "Usage: perl <arg1: all Turker transcripts> <arg2: directory with rover hyp files>>\n";
	exit(0);
}

open(INP, $ARGV[0]) or die "Cannot open $ARGV[0]\n";
$outdir = $ARGV[1];
$prefix = "turker";

while(<INP>) {
	chomp;
	($uttid, $transcripts) = split(/:/);
	@trns = split(/#/,$transcripts);
	for($t = 0; $t <= $#trns; $t++) {
		$trns[$t] =~ s/^\s+//g;
		$trns[$t] =~ s/\s+$//g;
		@lets = split(/\s+/,$trns[$t]);
		$pt=$t+1;
		$outfile = "$outdir/$prefix.$pt.ctm";		
		open(OUT, ">>$outfile");
		$time = 10.00;
		$dur = 0.10;
		for ($l=0; $l <= $#lets; $l++) {
			$let = $lets[$l];
			# rover converts everything to lowercase; so this ensures that uppercase is distinctly represented
			if($let =~ /[A-Z]/) {
				$let = "$let"."_upper";
			}
			print OUT "$uttid A $time $dur $let\n";
			$time += $dur;
		}
		close(OUT);
	}
}

close(INP);
