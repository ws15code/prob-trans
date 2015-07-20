#!/usr/bin/perl


#use Encode qw(encode decode);
#my %H = ();
my ($fst) = @ARGV;

open(FST, $fst) || die "Unable to read from $fst: $!";
my $i = 0;

while(<FST>) {
	chomp;
	@fields = split(/\s+/);	
	if (@fields != 4) { next ; }
	$node_start[$i] = $fields[0]; $node_end[$i]  = $fields[1];
	$sym_start[$i] =  $fields[2]; $sym_end[$i]   = $fields[3];
	#print "@fields\n";
	$i++;
}
close (FST);
my $narcs = $i - 1;

#foreach my $i (0..$count) {
	#print "$node_start[$i]   $node_end[$i]   $sym_start[$i]  $sym_end[$i]\n";
#}

# search for transitions out of 0
@id_zero_to_x_trans = ();
foreach my $i (0..$narcs) {
	if ($node_start[$i] == 0) {
		push @id_zero_to_x_trans, $i;	
	}
}

my $x_node;
foreach my $i (@id_zero_to_x_trans) {
	$x_node = $node_end[$i];
	
	my $j = 0;
	while ($node_start[$j] == $x_node) {
		
	}
	foreach my $j (0..$narcs) {
	 if ($j == $i)	{next;}
	 if ($node_start[$j] == $x_node) && 
		 if ($node_end[$j] == $x_node) 
			 
		 
	 }
	 
	}  
}
	
#print "$node_start[$i]   $node_end[$i]   $sym_start[$i]  $sym_end[$i]\n";



