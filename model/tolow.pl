#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

while (<STDIN>) {
	s/^([nt])([AEIOUÁÉÍÓÚ])/$1-$2/;
	print lc;
}

exit 0;
