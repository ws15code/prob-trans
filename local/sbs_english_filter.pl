#!/usr/bin/perl

# Mapping English words in SBS transcripts
# to its English pronunciation (using CMUdict).

$argerr = 0;
$ipafile = "";
$dictfile = "";
$idfile = "";
$idir = "";
$odir = "";
$engtag = "<EN>";

while ((@ARGV) && ($argerr == 0)) {
	if($ARGV[0] eq "--ipafile") {
		shift @ARGV;
		$ipafile = shift @ARGV;
	} elsif($ARGV[0] eq "--dictfile") {
		shift @ARGV;
		$dictfile = shift @ARGV;
	} elsif($ARGV[0] eq "--utts") {
		shift @ARGV;
		$idfile = shift @ARGV;
	} elsif($ARGV[0] eq "--idir") {
		shift @ARGV;
		$idir = shift @ARGV;
	} elsif($ARGV[0] eq "--odir") {
		shift @ARGV;
		$odir = shift @ARGV;
	} else {
		$argerr = 1;
	}
}

$argerr = 1 if ($ipafile eq "" || $dictfile eq "" || $idfile eq "" || $odir eq "");

if($argerr == 1) {
	print "Usage: ./sbs_english_filter.pl \n Required options\n";
	print " [--ipafile <2-column text file mapping ARPA phones to IPA phones>]\n";
	print " [--dictfile <CMUdict dictionary file>]\n"; 
	print " [--utts <List of utterance IDs>]\n";
	print " [--idir <Input directory to read transcripts>\n";
	print " [--odir <Output directory to write out transcripts>\n";
	print "Input: Transcript in SBS language\n";
	print "Output: Transcript with English words mapped to their corresponding pronunciations in IPA\n";
	exit 1;
}

open(my $ipa, '<:encoding(UTF-8)', $ipafile) or die "Cannot open file $ipafile\n";
open(DICT, $dictfile) or die "Cannot open dictionary file $dictfile\n";
open(IDS, $idfile) or die "Cannot open utterance ID file $idfile\n";
binmode STDERR, ':utf8';
binmode STDOUT, ':utf8';

%arpa2ipa = ();
while(<$ipa>) {
	chomp;
	($arpa_phn, $ipa_phn) = split(/\s+/);
	$arpa2ipa{$arpa_phn} = $ipa_phn;
}
close($ipa);

%dict = ();
while(<DICT>) {
	chomp;
	next if($_ =~ /^\;\;\;/); #ignoring comments
	($word, @pron) = split(/\s+/);
	$pronunciation = join(' ',@pron);
	$dict{$word} = $pronunciation; #choosing the last pronunciation of a word
}
close(DICT);

$phnseq = "";
while(<IDS>) {
	chomp;
	$trfile = "$idir/$_.txt";
	$ofile = "$odir/$_.txt";
	$string = "";
	open(my $FILE, '<:encoding(UTF-8)', $trfile) or die "Cannot open file $trfile\n";
	open(OUT, '>:encoding(UTF-8)', "$ofile");
	while($line = <$FILE>) {
		$line =~ s/[\"\\\/]//g;
		$line = lc($line);
		@words = split(/\s+/, $line);
		for($w = 0; $w <= $#words; $w++) {
			$wrd = $words[$w];
			$wrd =~ s/[\.,\!\?]//g;
			if(exists $dict{$wrd}) {
				@phones = split(/\s+/, $dict{$wrd});
				$string = $string."$engtag "; #Enclose English pronunciations within <EN> tags
				foreach $p (@phones) {
					$string = $string."$arpa2ipa{$p} ";
				}
				$string = $string."$engtag ";
			} else {
				$string = $string."$wrd ";
			}
		}
	}
	# Trimming the transcript
	$string =~ s/\s+$//g; $string =~ s/^\s+//g; $string =~ s/\s+/ /g;
	print OUT "$string\n";
	close($FILE);
	close(OUT);
}

close(IDS);
