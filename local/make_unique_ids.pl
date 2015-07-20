#!/usr/bin/perl
# Make unique ids given two files with symbol to integer mappings
# E.g.
# Input:
# Table 1:
# a 1
# b 2
# c 3
# Table 2:
# b 1
# d 2
# 
# Output:
# a 1
# b 2
# c 3
# d 4

use Encode qw(encode decode);
my %H = ();
my ($symtab1, $symtab2) = @ARGV;

open(SYMTAB, '<:encoding(UTF-8)', $symtab1) || die "Unable to read from $symtab1: $!";

while(<SYMTAB>) {
	chomp;
	@fields = split(/\s+/);
	$sym = $fields[0]; $id = $fields[1];
	if (!defined $H{$sym}) {
		$H{$sym} = $id;
	}
}
close(SYMTAB);
my $offset = $id + 1;

open(SYMTAB, '<:encoding(UTF-8)', $symtab2) || die "Unable to read from $symtab2: $!";
my $i = 0;
while(<SYMTAB>) {
	chomp;
	@fields = split(/\s+/);
	$sym = $fields[0]; $id = $i + $offset;
	if (!defined $H{$sym}) {
		$H{$sym} = $id;
		$i++;
	}	
}
close(SYMTAB);

binmode(STDOUT, ":encoding(UTF-8)");
foreach my $key (sort { $H{$a} <=> $H{$b} } keys %H) {
	print "$key $H{$key}\n";
}

