#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my %glan;

open(GLAN, "<:utf8", "../clean.txt") or die "Could not open clean word list";
while (<GLAN>) {
	chomp;
	$glan{$_} = 1;
}
close GLAN;

sub irishlc {
	(my $w) = @_;
	$w =~ s/^([nt])([AEIOUÁÉÍÓÚ])/$1-$2/;
	return lc($w);
}

# this is a stripped down version of filt.pl...
# assumes one sentence per line on input 
while (<STDIN>) {
	my $orig = $_;
	my $iomlan = 0;
	my $ok = 0;
	next if /<[^>]+>/;
	# just need to kill special tokens that contain "word" substrings
	s/(?:https?|ftp):\/\/[A-Za-z0-9\/.:=_%?&~+;\$@\#()-]+[A-Za-z0-9\/=]//g; # URLs, from alltokens.pl
	s/[A-Za-z0-9][A-Za-z0-9._]*@[A-Za-z0-9.]+[A-Za-z0-9]//g; # email, from alltokens.pl
	s/@[A-Za-z0-9_]+//g; # usernames
	while (m/((\p{L}|\p{M}|['-])+)/g) {
		my $match = $1;
		$match =~ s/^['-]+//;
		$match =~ s/['-]+$//;
		if (length($match)>1) {
			$iomlan++;
			$ok++ if (exists($glan{$match}) or exists($glan{irishlc($match)}));
		}
	}
	if ($iomlan > 0 and $iomlan < 125) {
		# since we want a standard corpus, can tighten this up even more?
		# 0.7, 0.8?
		print $orig if ($ok/$iomlan > 0.6);
	}
}

exit 0;
