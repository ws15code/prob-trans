#!/usr/bin/perl
#

$id = $ARGV[0];
@arcs = ();
while(<STDIN>) {
	chomp;
	push(@arcs, $_);
}

$olabel_seq = "";
@fields = split(/\s+/,$arcs[0]);
$olabel = "";
if($#fields > 2) { #arc
	$olabel = $fields[3];
}
if($olabel ne "-" && $olabel ne "") {
	$olabel_seq = $olabel_seq." $olabel";
}

for($a = $#arcs; $a > 0; $a--) {
	$arc = $arcs[$a];
	@fields = split(/\s+/,$arc);
	$olabel = "";
	if($#fields > 2) { #arc
		$olabel = $fields[3];
	}
	if($olabel ne "-" && $olabel ne "") {
		$olabel_seq = $olabel_seq." $olabel";
	}
}

$olabel_seq =~ s/^\s+//g;

print "$id $olabel_seq\n";
#close(INP);
