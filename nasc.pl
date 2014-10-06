#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my %phrases;
my $maxwords = 0;
my $gd = 0;

for my $a (@ARGV) {
	$gd = 1 if ($a eq '-d');
}
my $extension = '';
$extension = '-gd' if ($gd);

sub normalize {
	(my $w) = @_;
	$w =~ s/[ʼ’]/'/g;
	return lc($w);
}

open(MULTI, "<:utf8", "multi$extension.txt") or die "Could not open list of phrases: $!";
while (<MULTI>) {
	chomp;
	(my $phrase, my $ignore) = m/^([^ ]+) (.+)$/;
	my $numwords = 1 + ($phrase =~ tr/_//);
	$maxwords = $numwords if ($numwords > $maxwords);
	$phrases{normalize($phrase)}++;
}
close MULTI;

$maxwords = 5;

my @queue;
LINE: while (<STDIN>) {
	chomp;
	push @queue, $_;
	my $tot = scalar @queue;
	if ($tot > $maxwords) {
		my $w = shift @queue;
		$tot--;
		print "$w\n";
	}
	for (my $len=$tot; $len >= 2; $len--) {
		my $cand = join('_', @queue[0..($len-1)]);
		my $lccand = normalize($cand);
		if (exists($phrases{$lccand}) or $lccand =~ m/^([bdm]|dh)'_[^_]+$/) {
			for (0..($len-1)) {
				shift @queue;
			}
			$cand =~ s/^([BDMbdm]|[Dd]h)([ʼ’'])_/$1$2/i;
			print "$cand\n";
			next LINE;
		}
	}
}
for my $w (@queue) {
	print "$w\n";
}

exit 0;
