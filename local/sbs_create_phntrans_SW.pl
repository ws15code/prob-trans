#!/usr/bin/perl
#
# Creates phone sequences in IPA starting 
# from letter sequences in Swahili

$argerr = 0;
$g2pfile = "";
$idfile = "";
$transdir = "";
$engtag = "<EN>";
$silphone = "SIL";

while ((@ARGV) && ($argerr == 0)) {
	if($ARGV[0] eq "--g2p") {
		shift @ARGV;
		$g2pfile = shift @ARGV;
	} elsif($ARGV[0] eq "--utts") {
		shift @ARGV;
		$idfile = shift @ARGV;
	} elsif($ARGV[0] eq "--transdir") {
		shift @ARGV;
		$transdir = shift @ARGV;
	} elsif($ARGV[0] eq "--wordlist") {
		shift @ARGV;
		$wordlist = shift @ARGV;
	} else {
		$argerr = 1;
	}
}

$argerr = 1 if ($g2pfile eq "" || $idfile eq "" || $transdir eq "");

if($argerr == 1) {
	print "Usage: ./sbs_create_phntrans_SW.pl \n Required options\n";
	print " [--g2p <g2p .txt file>]\n [--utts <file with utt IDs>]\n";
	print " [--transdir <directory containing all the transcripts>]\n"; 
	print " [OPTIONAL --wordlist <list of Swahili words with pronunciations>]\n";
	print "Output: corresponding text in phonemes\n";
	exit 1;
}

open(my $g2p, '<:encoding(UTF-8)', $g2pfile) or die "Cannot open file $g2pfile\n";
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

%g2psyms_multi = ();
%g2psyms_single = ();
%multi2single_vocab = ();
@alph = (A..Z);

$cnt = 0;
while(<$g2p>){
	chomp;
	($gph, $phn) = split(/\t/);
	$gph =~ s/\s*$//g; $gph =~ s/^\s*//g;
	$phn =~ s/\s*$//g; $phn =~ s/^\s*//g;
	@lets = split(//, $gph);
	if($#lets == 0) {
		$g2psyms_single{$gph} = $phn;
	} else {
		$g2psyms_multi{$gph} = $phn;
		$multi2single_vocab{$gph} = $alph[$cnt];
		$g2psyms_single{$alph[$cnt]} = $phn; #add to single
		$cnt++;
	}
}

close($g2p);

%wordmap = ();
if($wordlist ne "") {
	open(WRD, $wordlist) or die "Cannot open the file $wordlist\n";
	while(<WRD>) {
		chomp;
		($wrd, $pron) = split(/\s+/);
		$wordmap{$wrd} = $pron;
	}
	close(WRD);
}

open(IDS, $idfile) or die "Cannot open file with list of utterance IDs, $idfile\n";

while($id = <IDS>) {
	chomp($id);
	$id =~ s/\.wav//g;
	$transfile = "$transdir/$id.txt";
	$phnseq = "";
	open(my $TRANS, '<:encoding(UTF-8)', $transfile) or die "Cannot open file $transfile\n";
	while(<$TRANS>) {
		chomp;
		$_ =~ s/^\-//g; $_ =~ s/\-$//g; #removing incomplete word markers
		$_ =~ s/[\'\"\\\/\{\}\(\)\[\]\,]//g; #removing punctuations
		$_ =~ s/\-/ /g; #catching words like african-american, etc.
		# replacing periods, exclamations, question marks (end-of-sent markers) with the sil phone
		$_ =~ s/\./$silphone /g; $_ =~ s/\!/$silphone /g; $_ =~ s/\?/$silphone /g;
		@words = split(/\s+/);
		$english = 0;
		for($w = 0; $w <= $#words; $w++) {
			$wrd = $words[$w];
			if($wrd eq $silphone) {
				print STDERR "Matched on silence $silphone\n";
				$phnseq .= "$wrd ";
				next;
			}
			$wrd = lc($wrd);
			next if ($wrd =~ /^\s*$/);
			if($wrd eq lc($engtag)) {
				$english = !$english; #toggle english variable
				next;
			}
			if($english == 1) { #print English phone and move on to the next one
				$phnseq = $phnseq."$wrd ";
				next;
			}
			$origwrd = $wrd;
			$wrd = resolvewords($wrd);
			next if ($origwrd ne $wrd); #this word was caught by the word list with pronunciations
			# first, make a pass over all multiletter graphemes and 
			# map them to a new single letter grapheme
			foreach $g (keys %g2psyms_multi) {
				$p = $g2psyms_multi{$g};
				$wrd =~ s/$g/$multi2single_vocab{$g}/g;
			}

			@gphs = split(//, $wrd);
			for($g = 0; $g <= $#gphs; $g++) {
				$gph = $gphs[$g];
				next if($gph =~ /\./ || $gph =~ /\!/ || $gph =~ /\?/); 
				print STDERR "Unresolved grapheme $gph in word $origwrd within transcript: $transfile\n" if(! exists $g2psyms_single{$gph});
				$phn = $g2psyms_single{$gph};
				$phnseq .= "$phn ";
			}
		}
	}
	close($TRANS);
	$phnseq =~ s/\s+$//g; $phnseq =~ s/^\s+//g; $phnseq =~ s/\s+/ /g;
	print "$phnseq\n" if($phnseq !~ /^\s*$/);
}

close(IDS);

sub resolvewords {
	($word) = @_;
	if(exists $wordmap{$word}) {
		$word = $wordmap{$word}; #replace word with pronunciation
	}
	return $word;
}
