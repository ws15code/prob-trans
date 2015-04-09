#!/usr/bin/perl

# prepare data/{wav.scp, spk2utt, utt2spk, spk2gender} files for sbs data
use File::Basename;

if (@ARGV != 2) {
    die "usage:  $0 wav.flist data/sbs \n";
}
($in_flist, $data) = @ARGV;

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
    $_ =~ m:/(.*)\/(.*)\.wav\s+$:i || die "bad scp line $_";
    $spkname = basename($1);
    $spkname  =~ tr/A-Z/a-z/;
    $uttname = $2;
    $uttname  =~ tr/A-Z/a-z/;    
    $spkname =~ s/_//g; # remove underscore from spk name to make key nicer.
    $key = $spkname."_".$uttname;    
    print P "$key $_" || die "Error writing to $out_scp";
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

