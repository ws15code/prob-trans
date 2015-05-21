#!/usr/bin/perl
#
# Takes an FST produced by parse_rover*.pl and prunes the 
# sausage links

# Read FST on the std input
#
$epsilon = 1E-6;
$del_discount = 1;
$eps_special = 0;
$expand_alphabet = 0;
$default_expand_threshold = 0.98;
$expand_threshold = $default_expand_threshold;
$with_classes = 1;
$classfile = "";

while ((@ARGV) && ($argerr == 0)) {
	if($ARGV[0] eq "--discount") {
		shift @ARGV;
		$del_discount = shift @ARGV;
	} elsif ($ARGV[0] eq "--eps-special") {
		shift @ARGV;
		$eps_special = 1;
	} elsif ($ARGV[0] eq "--noclasses") {
		shift @ARGV;
		$with_classes = 0;
	} elsif ($ARGV[0] eq "--classfile") {
		shift @ARGV;
		$classfile = shift @ARGV;
	} else {
		$argerr = 1;
	}
}

if($argerr == 1) {
	print "Usage: [--discount delete_discount] [--eps-special (false by default)] [--expand (no expansion of English alphabet by default) ] [--noclasses] [ --expand_threshold value (default = $default_expand_threshold)\n";
	print "Input: fst\n";
	print "Output: pruned fst\n";
	exit(1);
}

%classnames = ();
if($classfile ne "") { #read class information from file
	open(CF, $classfile) or die "Cannot open class file $classfile\n";
	while(<CF>) {
		($phn, $class) = split(/\s+/);
		$classnames{$phn} = $class;
	}
	close(CF);
} else { #assign class information here
	%classnames = (
			"a" => "VOWEL",
			"e" => "VOWEL",
			"i" => "VOWEL",
			"o" => "VOWEL",
			"u" => "VOWEL",
			"A" => "VOWEL",
			"E" => "VOWEL",
			"I" => "VOWEL",
			"O" => "VOWEL",
			"U" => "VOWEL",
			"Y" => "VOWEL",
			"k" => "KCLASS",
			"K" => "KCLASS",
			"g" => "KCLASS",
			"G" => "KCLASS",
			"q" => "KCLASS",
			"C" => "CCLASS",
			"J" => "CCLASS",
			"j" => "CCLASS",
			"t" => "DTCLASS",
			"T" => "DTCLASS",
			"d" => "DTCLASS",
			"D" => "DTCLASS",
			"p" => "PCLASS",
			"b" => "PCLASS",
			"B" => "PCLASS",
			"s" => "SCLASS",
			"S" => "SCLASS",
			"z" => "SCLASS",
			"Z" => "SCLASS",
			"v" => "VCLASS",
			"w" => "VCLASS",
			"m" => "NCLASS",
			"n" => "NCLASS",
			);
}

$finalstate = "";
%symbols = ();
%weights = ();
$maxstate = 0;

while(<STDIN>) {
	chomp;
	@fields = split(/\s+/);
	if($#fields > 2) { #arc
		$key = $fields[0];
		$sym = $fields[2];
		$maxstate = $key if ($key > $maxstate);
		$wt = exp(-$fields[4]); # change to prob
		$wt = $wt * $del_discount if $sym eq "-";
		if(!exists $symbols{$key}) {
			$symbols{$key} = $sym;
			$weights{$key} = $wt;
		} else {
			$symbols{$key} .= ":$sym";
			$weights{$key} .= ":$wt";
		}
	} else {
		$finalstate = $_;
	}
}

$edgecnt = 1;
for($k = 0; $k <= $maxstate; $k++) {
	@syms = split(/:/,$symbols{$k});
	@wts = split(/:/,$weights{$k});

	#populate class weights
	%classwts = ();
	$maxclasswt = 0;
	for($w = 0; $w <= $#wts; $w++) {
		$class = $syms[$w];
		$class = $classnames{$syms[$w]} if ($with_classes == 1 && exists $classnames{$syms[$w]});
		$classwts{$class} += $wts[$w];
		$maxclasswt = $classwts{$class}  if ($maxclasswt < $classwts{$class} && $class ne "-"); 
	}

	@sorted_indices = sort { $wts[$b] <=> $wts[$a] } 0..$#wts;
	@wts = @wts[@sorted_indices];
	@syms = @syms[@sorted_indices];
	$found = 0; $foundwt = 0;
	$linkcnt = 0;
	# Only retaining the max "set" of wts
	for($w = 0; ($found == 0 || $wts[$w] >= $foundwt - $epsilon) && $w <= $#wts; $w++) {
		$class = $syms[$w];
		$class = $classnames{$syms[$w]} if ($with_classes == 1 && exists $classnames{$syms[$w]});
		next if $classwts{$class} < $maxclasswt - $epsilon;
		if (!$eps_special || $syms[$w] ne "-") { #if eps is special keep looking if the top one is "-"
			$found = 1; $foundwt = $wts[$w];
		}
		$score = -log($wts[$w]);
		$label = $syms[$w];
		if ($expand_alphabet == 1 && $wts[$w] > $expand_threshold && $label ne "-") {
			$label .= "*";
		}
		print "$k\t",$k+1,"\t$label\t$label\t$score\n";
		$linkcnt++;
	}
	$edgecnt *= $linkcnt;
}

print "$finalstate\n";

print STDERR "$edgecnt\n";
