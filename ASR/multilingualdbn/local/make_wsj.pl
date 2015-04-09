#!/usr/bin/perl

# prepare data/{wav.scp, spk2utt, utt2spk, spk2gender} files for sbs data

if (@ARGV != 3) {
    die "usage:  $0 wav.flist path-to-sph2pipe data/wsj \n";
}
($in_flist, $sph2pipe, $data) = @ARGV;

my $out_scp="$data"."/"."wav.scp";
my $utt2spk="$data"."/"."utt2spk";
my $spk2utt="$data"."/"."spk2utt";
my $spk2gender="$data"."/"."spk2gender";
my $n = 0;

#unless (-e $data) {
#		( system("mkdir -p $data 2>/dev/null") == 0 ) or die "Unable to create $data\n";
#}

open(G, "<$in_flist") || die "Opening file list $in_flist";
open(P, ">$out_scp") || die "Open output scp file $out_scp";
open(UTT2SPK, ">$utt2spk") || die "Open output utt2spk file $utt2spk";

# create wav.scp, utt2spk
while(<G>) {
	chomp $_;    
	$_ =~ m:^\S+/(\w+)\.[wW][vV]1$: || die "Bad line $_";    
    $spkname = "english";    
    $uttname = "english"."_".$1;
    $uttname  =~ tr/A-Z/a-z/;        
    $key = $spkname."_".$uttname;    
    print P "$key $sph2pipe -f wav $_ |\n" || die "Error writing to $out_scp";
    print UTT2SPK "$key $spkname\n" || die "Error writing to $utt2spk"; 
    $n++;
}
close(P) || die "Closing output file $out_scp.";
close(UTT2SPK) || die "Closing output file $utt2spk.";

# create spk2utt
system ("perl utils/utt2spk_to_spk2utt.pl $utt2spk > $spk2utt");

# create spk2gender
my $cmd=q{awk '{print $2 " " "f"}' }; 
$cmd=$cmd." $utt2spk | sort -u > $spk2gender";
#print "$cmd\n";
(system($cmd) == 0) or die "$?\n";
