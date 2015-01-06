#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

die "Usage: wer.pl FILE1 FILE2" unless (scalar @ARGV == 2);

my @a;
my @b;

open(A, "<:utf8", $ARGV[0]) or die "Could not open $ARGV[0]: $!";
while (<A>) {
	chomp;
	push @a, $_;
}
close A;

open(B, "<:utf8", $ARGV[1]) or die "Could not open $ARGV[1]: $!";
while (<B>) {
	chomp;
	push @b, $_;
}
close B;

my $m = scalar @a;
my $n = scalar @b;

# d[i,j] is stored as $d{"i|j"}
my %d;

for my $i (0..$m) {
	$d{"$i|0"} = $i;
}

for my $j (0..$n) {
	$d{"0|$j"} = $j;
}

for my $j (1..$n) {
	my $left = $j - 1;
	for my $i (1..$m) {
		my $up = $i - 1;
		if ($a[$i-1] eq $b[$j-1]) {
			$d{"$i|$j"} = $d{"$up|$left"};
		}
		else {
			my $smallest = $d{"$up|$j"};
			$smallest = $d{"$i|$left"} if ($d{"$i|$left"} < $smallest);
			$smallest = $d{"$up|$left"} if ($d{"$up|$left"} < $smallest);
			$d{"$i|$j"} = $smallest + 1;
		}
	}
}
print $d{"$m|$n"} / (1.0*$n)."\n";

exit 0;
