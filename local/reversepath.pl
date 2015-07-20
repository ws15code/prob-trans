#!/usr/bin/perl
#
# LAB: JSALT Workshop, June 26th, 2015
# Reading off the output labels from 
# the output returned by fstshortestpath

@arcs = ();

if(-t STDIN) {
	print "Usage: ./reversepath.pl\n";
	print "Input from command line: fstshortestpath | fstprint output\n";
	print "Output: Sequence of output labels\n";
	exit 1;
}

while(<STDIN>) {
    chomp;
    push(@arcs, $_);
}

$olabel_seq = "";
@fields = split(/\s+/,$arcs[0]); #Reading the first line
$olabel = "";
if($#fields > 2) { #arc
    $olabel = $fields[3];
}
if($olabel ne "-" && $olabel ne "") {
    $olabel_seq = $olabel_seq." $olabel";
}

for($a = $#arcs; $a > 0; $a--) { #Reading arcs backwards;based on how the shortest path FST is printed typically
    $arc = $arcs[$a];
    @fields = split(/\s+/,$arc);
    $olabel = "";
    if($#fields > 2) { #arc
        $olabel = $fields[3];
    }
    if($olabel ne "-" && $olabel ne "") { #ignoring epsilon
        $olabel_seq = $olabel_seq." $olabel";
    }
}

$olabel_seq =~ s/^\s+//g;

print "$olabel_seq";
