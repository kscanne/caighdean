#!/usr/bin/perl

use strict;
use warnings;
use Encode qw(decode);
use Unicode::Normalize;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

while (<STDIN>) {
	print NFC(Encode::decode('UTF-8', $_));
}

exit 0;
