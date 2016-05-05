#!/usr/bin/perl
# filters out (or keeps) sentences that have too many punctuation marks,
# too many pure number tokens, or else too many capital words.  
# Sentences of this type often correspond to navigation
# on web pages, or headings, or bullet lists, or the like.
# Usually gets its input from the output
# of a sentence segmenter like abairti-dumb, followed by
# alltokens.pl or togail xx alltokens
#   Usage: cat CORPUS | abairti-dumb | filt.pl en -v | alltokens.pl | denoise.pl [-v]
#  good to run it through filt.pl first so we don't have to worry about
#  tokenizing URLs, emails, etc.

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

die "Incorrect usage!" if ($#ARGV != -1 and $#ARGV != 0);
# With the -v it filters out "bad" stuff.
my $filter = ($#ARGV == 0 and $ARGV[0] eq '-v');

my $ints="’:.'-";

my $curr = '';
my $tokens = 0;
my $punc = 0;  # really anything not containing a letter, so numbers too
my $caps = 0;

while (<STDIN>) {
	chomp;
	if ($_ eq '\n') {
		print $curr if ($filter == ($punc/$tokens < 0.4 and $caps/$tokens < 0.4));
		$tokens = 0;
		$punc = 0;
		$caps = 0;
		$curr = '';
	}
	else {
		$curr .= "$_\n";
		$tokens++;
		$punc++ if ($_ !~ /\p{L}/);
		$caps++ if ($_ ne lc($_));
	}
}
exit 0;
