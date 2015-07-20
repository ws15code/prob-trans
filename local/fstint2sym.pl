#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter
use strict;
use Getopt::Long;
use Encode qw(encode decode);
 
my ($isymbols, $osymbols);
my @fields = ();
my $usage = "perl $0 --isymbols input.vocab --osymbols output.vocab fstint.txt\n";
my ($sym, $id);
GetOptions ("isymbols=s" => \$isymbols,      # input vocab
            "osymbols=s" => \$osymbols);     # output vocab

my ($fstint) = @ARGV;   
die "$usage" unless(@ARGV == 1);

# Create integer to symbol map for input vocab
my %INVOCAB = ();
open(SYMTAB, '<:encoding(UTF-8)', $isymbols) || die "Unable to read from $isymbols: $!";
while(<SYMTAB>) {
	chomp;
	@fields = split(/\s+/);
	$sym = $fields[0]; $id = $fields[1];
	if (!defined $INVOCAB{$id}) {
		$INVOCAB{$id} = $sym;
	}
}
close(SYMTAB);

# Create integer to symbol map for output vocab
my %OUTVOCAB = ();
open(SYMTAB, '<:encoding(UTF-8)', $osymbols) || die "Unable to read from $osymbols: $!";
while(<SYMTAB>) {
	chomp;
	@fields = split(/\s+/);
	$sym = $fields[0]; $id = $fields[1];
	if (!defined $OUTVOCAB{$id}) {
		$OUTVOCAB{$id} = $sym;
	}
}
close(SYMTAB);

# Read the FST
binmode(STDOUT, ":encoding(UTF-8)");
open(FSTINTF, "<$fstint") or die "Cannot open fst file '$fstint': $!";
while(<FSTINTF>) {
	chomp;
	@fields = split(/\s+/);	
	if (@fields == 1) { # node is a terminal node - has only 1 field 
		print "$fields[0]\n";		
	} else	{	# node has a transitions - has 4 fields 
		print "$fields[0]\t$fields[1]\t$INVOCAB{$fields[2]}\t$OUTVOCAB{$fields[3]}\n";		
	}		
}
close (FSTINTF);
