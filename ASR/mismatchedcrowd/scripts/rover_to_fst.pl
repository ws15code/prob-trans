#!/usr/bin/perl
#
# Parse rover output to create probabilistic automata for turker transcripts

$argerr = 0;

$threshold = 0.0000001; #threshold for reranking algorithm
$del_discount = 1;
$expand_alphabet = 0;
$default_expand_threshold = 0.6;
$expand_threshold = $default_expand_threshold;
$simfile = "";
$transfile = "";
$rerank_mode = 0; # no reranking
$iterate = 0;
$dampfactor = 1;
$debug = 0;
$rankprint = 0;
$nbhdsize = 1;
$simscoredelta = 0.067;

while ((@ARGV) && ($argerr == 0)) {
	if($ARGV[0] eq "--discount") {
		shift @ARGV;
		$del_discount = shift @ARGV;
	} elsif ($ARGV[0] eq "--simscores") {
		shift @ARGV;
		$simfile = shift @ARGV;
	} elsif ($ARGV[0] eq "--nbhdsize") {
		shift @ARGV;
		$nbhdsize = shift @ARGV;
	} elsif ($ARGV[0] eq "--rerank") {
		shift @ARGV;
		$rerank_mode = shift @ARGV;
		$iterate = 1 if ($rerank_mode == 1 || $rerank_mode == 3 || $rerank_mode == 5);
	} elsif ($ARGV[0] eq "--dampfactor") {
		shift @ARGV;
		$dampfactor = shift @ARGV;
	} elsif ($ARGV[0] eq "--expand") {
		shift @ARGV;
		$expand_alphabet = 1;
	} elsif ($ARGV[0] eq "--expand_threshold") {
		shift @ARGV;
		$expand_alphabet = 1;
		$expand_threshold = shift @ARGV;
	} elsif ($ARGV[0] eq "--rankprint") {
		shift @ARGV;
		$rankprint = 1;
	} elsif ($ARGV[0] eq "--debug") {
		shift @ARGV;
		$debug = 1;
	} elsif ($transfile eq "") {
		$transfile = shift @ARGV;
	} else {
		$argerr = 1;
	}
}

$argerr = 1 if ($transfile eq "");

if($argerr == 1) {
	print "Usage: [--debug] [--nbhdsize nbhdsize (default is 1)] [--discount delete_discount] [--rerank <mode> (default is 0: no reranking)] [--dampfactor <damp factor>] [--simscores  <file with similarity scores>] [--expand (no expansion of English alphabet by default) ] [ --expand_threshold value (default = $default_expand_threshold) <file with turker transcripts>\n";
	print "Input: rover putative file (for a single utterance)\n";
	print "Output: an equivalent annotated fst\n";
	print "Rerank modes: 0 = no reranking; 1 = iterative, cluster-based; 2 = local, non-iterative; 3 = local, iterative; 4 = local, non-iterative windowed, 5 = local, iterative windowed\n";
	exit(1);
}


open(MTURK, $transfile) or die "Cannot open $transfile\n";
if ($simfile ne "") {
	open(SIMFILE, $simfile) or die "Cannot open $simfile\n";
}

$numturkers = 0;
$uttid = "";
@trans = (); # array to hold the turker transcripts for uttid
%linkscores = ();

# sscores: array of arrays of scores for turkers
@sscores = ();
@origscores = ();
# slabels: array of arrays of labels by turkers 
@slabels = ();
# scliques:  array of hashes mapping each letter to set of turker ids
@scliques = ();

$linkctr = 0;
while(<STDIN>) {
	chomp;
	if ($_ =~ /<putative_tag file=([^ ]*) /) { #starting a sausage link
		$file = $1;
		die "Multiple utterances not allowed in input!" if ($uttid ne "" && $file ne $uttid);
		if ($uttid eq "") {
			$uttid = $file;

			#get the turker transcripts and similarity scores (if available)
			while(($line=<MTURK>) && !@trans) {
				chomp($line);
				($u, $transcripts) = split(/:/,$line);
				if (lc($u) eq lc($uttid)) {
					@trans = split(/#/,$transcripts);
				}
			}
			close(MTURK);
			die "Transcript for utterance $uttid not found!\n" if !@trans;
			$numturkers = $#trans + 1;

			while( ($simfile ne "") && ($line=<SIMFILE>) && (!%linkscores)) {
				chomp($line);
				($u, @sim) = split(/,/,$line);
				if (lc($u) eq lc($uttid)) {
					$linkscoretotal = 0;
					foreach $turk (@sim) {
						($turkno,$score) = split(/:/,$turk);
						$score += $simscoredelta;
						$turkno = $turkno - 1; # making 0 indexed
						$linkscores{$turkno} = $score;
						$linkscoretotal += $score;
					}
				}
			}
			close(SIMFILE) if $simfile ne "";

			
			#
			if(!%linkscores) {
				# set all to 1
				for ($i = 0; $i < $numturkers; $i++) {
					$linkscores{$i}=1/$numturkers;
				}
				$linkscoretotal = 1;
			} else {
				# normalize simscores
				for ($i = 0; $i < $numturkers; $i++) {
					$linkscores{$i} /= $linkscoretotal;
				}
				$linkscoretotal = 1;
			}
		}

		$totalwt = 0; # total weight on arcs with non-delete labels
		$delete_count = 0; # explicit flag if "-" label appeared

		# initialize all labels to "-"
		for ($i=0; $i < $numturkers; $i++) {
			$slabels[$linkctr][$i] = "-";
		}

		$line = <STDIN>;
		while ($line !~ /<\/putative_tag/) {
			if($line =~ /<attrib tag=\"([^"]*)\"/) {
				$label = $1;
				if($label=~/@/) {
					$label = "-";
					$delete_count++;
				}
				else { # tnum is only available if label is not delete
					$tnum = $line;
					$tnum =~ s/.*tag1=\".*\.([0-9]*)\.ctm\"/\1/;
					$tnum = $tnum - 1; #making it 0-indexed

					$slabels[$linkctr][$tnum] = $label;
					$sscores[$linkctr][$tnum] = $linkscores{$tnum};
					# add to scliques
					$cliquestring = "";
					$cliquestring = $scliques[$linkctr]{$label} if (exists $scliques[$linkctr]{$label});
					$cliquestring .= "$tnum ";
					$scliques[$linkctr]{$label} = $cliquestring;
					$totalwt += $linkscores{$tnum};
				}
			}
			$line = <STDIN>;
		}
		# now populate sscores and scliques for the "-" labels
		$delscore = 0;
		$delscore = ($linkscoretotal - $totalwt) / $delete_count if $delete_count > 0;
		$deladjust = $linkscoretotal/($linkscoretotal * $del_discount + $totalwt * (1 - $del_discount));
		for ($tnum=0; $tnum < $numturkers; $tnum++) {
			if ($slabels[$linkctr][$tnum] eq "-") {
					$sscores[$linkctr][$tnum] = $del_discount * $delscore * $deladjust;
					# add to scliques
					$label = "-";
					$cliquestring = "";
					$cliquestring = $scliques[$linkctr]{$label} if (exists $scliques[$linkctr]{$label});
					$cliquestring .= "$tnum ";
					$scliques[$linkctr]{$label} = $cliquestring;
			} else {
				$sscores[$linkctr][$tnum] *= $deladjust; #re-normalizing after applying del_discount
				
			}
		}

		$linkctr++;
	}
}

if($expand_alphabet == 1) {
	#maintain origscores in order to expand the alphabet
	#using these initial scores
	for $i ( 0 .. $#slabels ) {
		for $j ( 0 .. $#{ $slabels[$i] } ) {
			$origscores[$i][$j] = $sscores[$i][$j];
		}
	}
}

# if rerank
if ($rerank_mode == 1) {
	rerank_routine();
} elsif ($rerank_mode >= 2) {
	rerank_local_routine();
}

replaceclass(); #replace class labels with characters

if ($debug == 1) {
	print_rover();
}

if ($rankprint == 1) {
	print_rankscores();
}


if($expand_alphabet == 1) {
	for ($link=0; $link < $linkctr; $link++) {
		foreach $k (keys %{ $scliques[$link] } ) {
			$cliquestring = $scliques[$link]{$k};
			$cliquestring =~ s/ $//;
			@tnums = split(/ /,$cliquestring);
			$labelwt = 0;
			foreach $t (@tnums) {
				$labelwt += $origscores[$link][$t];
			}
			if($labelwt > $expand_threshold && $k ne "-") {
				$newkey = "$k*";
				$scliques[$link]{$newkey} = $cliquestring;
				delete $scliques[$link]{$k};
				foreach $t (@tnums) {
					$slabels[$link][$t] = $newkey;
				}
			}
		}
	}
}

# finally print
$state = 0;
for ($link=0; $link < $linkctr; $link++) {
	foreach $k (keys %{ $scliques[$link] } ) {
		$cliquestring = $scliques[$link]{$k};
		$cliquestring =~ s/ $//;
		@tnums = split(/ /,$cliquestring);
		$labelwt = 0;
		foreach $t (@tnums) {
			$labelwt += $sscores[$link][$t];
		}
		print "$state\t", $state+1, "\t$k\t$k\t", -log($labelwt/$linkscoretotal), "\n";
		#print "$state\t", $state+1, "\t$k\t$k\t", -log($labelwt/$linkscoretotal), "\n" if $k ne "-";
		#print "$state\t", $state+1, "\t$k\t$k\t", -log($del_discount*$labelwt/$linkscoretotal), "\n" if $k eq "-";
	}
	$state++;
}
print "$state\n";

sub replaceclass {
	@scliques = ();
	for $i ( 0 .. $#slabels ) {
		for $j ( 0 .. $#{ $slabels[$i] } ) {
			$label = "-";
			if($slabels[$i][$j] ne "-") {
				# replace classname by a character
				($first,@rest) = split(/\s+/,$trans[$j]);
				$label = $first;
				$rt = join(' ',@rest[0..$#rest]);
				$trans[$j] = $rt;
			}
			#print STDERR "slabel = $slabels[$i][$j] in link $i turker id $j, replaced by $first\n";
			$cliquestring = "";
			$cliquestring = $scliques[$i]{$label} if (exists $scliques[$i]{$label});
			$cliquestring .= "$j ";
			$scliques[$i]{$label} = $cliquestring;
			$slabels[$i][$j] = $label;
		}
	}
}

sub rerank_local_routine {

	$stop_flag = 0;
	for $i ( 0 .. $#sscores ) {
		for $j ( 0 .. $#{ $sscores[$i] } ) {
			$sscores[$i][$j] = 0;
			for $k ( 0 .. $#{ $sscores[$i] } ) {
				$delta = ($simfile ne "") ? $linkscores{$j} : 1;
				$sscores[$i][$j] += $delta if ($slabels[$i][$j] eq $slabels[$i][$k]);
			}
		}
	}

	while ($stop_flag == 0) {
		print STDERR "." if $rankprint == 0;
		# copy scores to prev_scores
		for $i ( 0 .. $#sscores ) {
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$prev_scores[$i][$j] = $sscores[$i][$j];
			}
		}

		for $i ( 0 .. $#sscores ) {
			undef $minscore;
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$sscores[$i][$j] = 0;
				for $h ( 0 .. $#sscores ) {
					if ($rerank_mode == 4 || $rerank_mode == 5) { #windowed
						$scale = (abs($h-$i) <= $nbhdsize) ? 1 : 0;
					}
					else {
						$scale = ( $dampfactor ** abs($h-$i) );
					}
					$sscores[$i][$j] += $scale*$prev_scores[$h][$j];
				}
				$minscore = $sscores[$i][$j] if (!defined $minscore) || ($minscore > $sscores[$i][$j]);
			}

# shift to make least score = $simscoredelta
			$newlinkscoretotal = 0;
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$sscores[$i][$j] -= ($minscore - $simscoredelta);
				$newlinkscoretotal += $sscores[$i][$j];
			}

# renormalize the link scores
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$sscores[$i][$j] /= $newlinkscoretotal;
			}
		}

		# checking for stop criterion
		$stop_flag = 1;
		if($iterate == 1) {
			for $i ( 0 .. $#sscores ) {
				for $j ( 0 .. $#{ $sscores[$i] } ) {
					if ( abs($prev_scores[$i][$j] - $sscores[$i][$j]) > $threshold) {
						$stop_flag = 0;
						last;
					}
				}
				last if $stop_flag == 0;
			}
		}
	}
	print STDERR "\n" if $rankprint == 0;
}

sub rerank_routine {
	$stop_flag = 0;
	@prev_scores = ();
	@clique_scores = ();
	for $i ( 0 .. $#sscores ) {
		for $j ( 0 .. $#{ $sscores[$i] } ) {
			$label = $slabels[$i][$j];
			$cliquestring = $scliques[$i]{$label};
			$cliquestring =~ s/ $//;
			@tnums = split(/ /,$cliquestring);
			$cliquesum = 0;
			foreach $t (@tnums) {
				$cliquesum += $sscores[$i][$t];	
			}
			foreach $t (@tnums) {
				$clique_scores[$i][$t] = $cliquesum;
			}
		}
	}
	print STDERR "Reranking: " if $rankprint == 0;
	while ($stop_flag == 0) {
		print STDERR "." if $rankprint == 0;
		# copy scores to prev_scores
		for $i ( 0 .. $#sscores ) {
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$prev_scores[$i][$j] = $sscores[$i][$j];
			}
		}

		for $i ( 0 .. $#sscores ) {
			$newlinkscoretotal = 0;
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$sscores[$i][$j] = 0;
				$label = $slabels[$i][$j];
				$cliquestring = $scliques[$i]{$label};
				$cliquestring =~ s/ $//;
				@tnums = split(/ /,$cliquestring);
				$cliquesize = $#tnums+1;
				for $k ( 0 .. $#sscores) {
					if (abs($k - $i) <= $nbhdsize && $k != $i) {
						$nlabel = $slabels[$k][$j];
						$cliquestr = $scliques[$k]{$nlabel};
						$cliquestr =~ s/ $//;
						@nnums = split(/ /,$cliquestr);
						$ncliquesize = $#nnums + 1;
						$sscores[$i][$j] += $clique_scores[$k][$j]/(2*$nbhdsize*$ncliquesize);
					}
				}
				foreach $t (@tnums) {
					$sscores[$i][$j] += $prev_scores[$i][$t]/$cliquesize;
					#print STDERR "adding own $prev_scores[$minusi][$j] to sscores of $i and turkid $j\n";
				}
				
				# scaling by turker's weight
				$sscores[$i][$j] *= $linkscores{$j};
				
				if ($slabels[$i][$j] eq "-") {
					$sscores[$i][$j] *= $del_discount;
				}


				$newlinkscoretotal += $sscores[$i][$j];
			}
			# renormalize the link scores
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$sscores[$i][$j] /= $newlinkscoretotal;
			}
		}

		# Update the cliques
		for $i ( 0 .. $#sscores ) {
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				$label = $slabels[$i][$j];
				$cliquestring = $scliques[$i]{$label};
				$cliquestring =~ s/ $//;
				@tnums = split(/ /,$cliquestring);
				$cliquesum = 0;
				foreach $t (@tnums) {
					$cliquesum += $sscores[$i][$t];	
				}
				foreach $t (@tnums) {
					$clique_scores[$i][$t] = $cliquesum;
				}
			}
		}

		# checking for stop criterion
		$stop_flag = 1;
		for $i ( 0 .. $#sscores ) {
			for $j ( 0 .. $#{ $sscores[$i] } ) {
				if ( abs($prev_scores[$i][$j] - $sscores[$i][$j]) > $threshold) {
					$stop_flag = 0;
					last;
				}
			}
			last if $stop_flag == 0;
		}

	}
	print STDERR "\n" if $rankprint == 0;
}

sub print_rover {
	$n = $numturkers - 1;
	for $j ( 0 .. $n ) {
		for $i ( 0 .. $#slabels ) {
			#printf STDERR "%s:%0.5f\t",$slabels[$i][$j],$sscores[$i][$j]*$numturkers;
			print STDERR "$slabels[$i][$j] ";
		}
		print STDERR "\n";
	}
}


sub print_rankscores {
	print STDERR uc($uttid);
	@rankscores  = ();
	for $j ( 0 .. $#{ $sscores[0] }) {
		for $i ( 0 .. $#sscores ) {
			$rankscores[$j] += $sscores[$i][$j];
		}
		$rankscores[$j] /= $#sscores;
	}


	@sorted_scoreindices = sort { $rankscores[$b] <=> $rankscores[$a] } 0..$#rankscores;
	$maxscore = $rankscores[$sorted_scoreindices[0]];
	$minscore = $rankscores[$sorted_scoreindices[$#rankscores]];

	die "Can't scale scores as they are all equal!" if $maxscore == $minscore;

	for $j ( 0 .. $#rankscores) {
		$rankscores[$j] -= $minscore;
		$rankscores[$j] /= ($maxscore-$minscore);
	}

	for $j ( 0 .. $#sorted_scoreindices ) {
		$index = $sorted_scoreindices[$j];
		print STDERR ",", $index+1, ":$rankscores[$index]";
	}
	print STDERR "\n";
}

