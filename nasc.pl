#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my %phrases;
my $maxwords = 0;
my $extension = '';

for my $a (@ARGV) {
	$extension = '-gd' if ($a eq '-d');
}

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

# looks for longest multiword (only) at front of queue
# prints and shifts words off if one is found
sub look_for_multi {
	(my $q) = @_;
	my $tot = scalar @{$q};
	for (my $len=$tot; $len >= 2; $len--) {
		my $cand = join('_', @$q[0..($len-1)]);
		my $lccand = normalize($cand);
		if (exists($phrases{$lccand}) or $lccand =~ m/^([bdm]|dh)'_[^_]+$/) {
			for (0..($len-1)) {
				shift @{$q};
			}
			$cand =~ s/^([BDMbdm]|[Dd]h)([ʼ’'])_/$1$2/i;
			print "$cand\n";
			return;
		}
	}

}

my @queue;
while (<STDIN>) {
	chomp;
	push @queue, $_;
	if (scalar @queue > $maxwords) {
		my $w = shift @queue;
		print "$w\n";
	}
	look_for_multi(\@queue);
}
while (scalar @queue > 0) {
	my $w = shift @queue;
	print "$w\n";
	look_for_multi(\@queue);
}

exit 0;
