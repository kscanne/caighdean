#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

if ($#ARGV != 0) {
	die "Usage: cat CORPUS | alltokens.pl | perl ngramify.pl n";
}

my $n = $ARGV[0];

my @queue;
while (<STDIN>) {
	chomp;
	push @queue, $_;
	if (scalar @queue == $n) {
		print "@queue\n";
		shift @queue;
	}
}

exit 0;
