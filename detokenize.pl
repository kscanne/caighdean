#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# set this flag true if no need for space before next token
# For example, start of doc, left parens, brackets, or SGML markup tag
my $suppress = 1;
while (<STDIN>) {
	chomp;
	my $s = $_;
	my $t = $_;
	if (/ => /) {
		$s =~ s/ =>.*$//;
		$t =~ s/^.* => //;
		$t =~ s/ /_/g;
	}
	if ($s eq $t) {
		if ($s eq '\n') {
			$suppress = 1;
			print "\n";
		}
		else {
			unless ($suppress == 1 or $s =~ /^([.,;”:!?%})]|<[^>]+>)$/) {
				print " ";
			}
			$suppress = ($s =~ /^([“\$(\[#{]|<[^>]+>)$/);
			print $s;
		}
	}
	else {
		print " ^$s^ $t";
	}
}

exit 0;
