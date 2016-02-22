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
	$extension = '-gv' if ($a eq '-x');
}

# apostrophe norm. only relevant for STDIN: ASCII-only aposts in multi*
# don't want to link "ana_\n_\n_mhór" of course
# something like "ny_\n_sloo_\n_na" is more subtle; don't link for now
sub normalize {
	(my $w) = @_;
	$w =~ s/[ʼ’]/'/g;
	$w =~ s/_\\n_/_/;  # just first one for now; see comments above
	return lc($w);
}

open(MULTI, "<:utf8", "multi$extension.txt") or die "Could not open list of phrases multi$extension.txt: $!";
while (<MULTI>) {
	chomp;
	(my $phrase, my $ignore) = m/^([^ ]+) (.+)$/;
	my $numwords = 1 + ($phrase =~ tr/_//);
	$maxwords = $numwords if ($numwords > $maxwords);
	$phrases{normalize($phrase)}++;
}
close MULTI;

sub shift_and_print {
	(my $q, my $cand, my $len) = @_;
	for (0..($len-1)) {
		shift @{$q};
	}
	$cand =~ s/^([BDMbdm]|[Dd]h)([ʼ’'])_/$1$2/i;
	$cand =~ s/_\\n_(.+)$/_$1\n\\n/;
	print "$cand\n";
}

# looks for longest multiword (only) at front of queue
# prints and shifts words off if one is found
sub look_for_multi {
	(my $q) = @_;
	my $tot = scalar @{$q};
	for (my $len=$tot; $len >= 2; $len--) {
		my $cand = join('_', @$q[0..($len-1)]);
		my $lccand = normalize($cand);
		if (exists($phrases{$lccand}) or $lccand =~ m/^([bdm]|dh)'_[^_]+$/) {
			shift_and_print($q, $cand, $len);
			return;
		}
		else {
			if ($lccand =~ m/^'/) {
				$lccand =~ s/^'//;
				if (exists($phrases{$lccand})) {
					$cand =~ s/^([ʼ’'])//;
					print "$1\n";
					shift_and_print($q, $cand, $len);
					return;
				}
			}
			if ($lccand =~ m/'$/) {
				$lccand =~ s/'$//;
				if (exists($phrases{$lccand})) {
					$cand =~ s/([ʼ’'])$//;
					shift_and_print($q, $cand, $len);
					print "$1\n";
					return;
				}
			}
		}
	}
	my $w = shift @{$q};
	print "$w\n";
}

my @queue;
while (<STDIN>) {
	chomp;
	push @queue, $_;
	look_for_multi(\@queue) if (scalar @queue > $maxwords);
}
while (scalar @queue > 0) {
	look_for_multi(\@queue);
}

exit 0;
