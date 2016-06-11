#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

if ($#ARGV != 0 or $ARGV[0] !~ m/^-[stfap]$/) {
    die "Usage: $0 [-s|-t|-f|-a|-p]\n  -s: source language only\n  -t: target language only\n  -f: focloir.ie NEID output\n  -a: mouseover annotations in HTML\n  -p: parallel text in HTML";
}

my $dispatch = {
	'-s' => sub { (my $s, my $t) = @_; return $s; },
	'-t' => sub { (my $s, my $t) = @_; return $t; },
	'-f' => sub { (my $s, my $t) = @_; $t =~ s/ /_/g; return "^$s^ $t"; },
	'-a' => sub { (my $s, my $t) = @_; return "<span class=\"tooltip\">$s<span>$t</span></span>"; },
};
# set this flag true if no need for space before next token
# For example, start of doc, left parens, brackets, or SGML markup tag
my $suppress = 1;
my $ascii_double_quote_parity = 0;

# always assume format of input is the same as output of tiomanai.sh,
# i.e. a pair of source/target tokens separated by '=>' on each line
while (<STDIN>) {
	chomp;
	(my $s, my $t) = /^(.+) => (.+)$/;
	if ($s eq '\n') {
		$suppress = 1;
		print "\n";
	}
	else {
		if ($s eq '"') {
			$suppress = 1 if ($ascii_double_quote_parity==1);
			$ascii_double_quote_parity = 1 - $ascii_double_quote_parity;
		}
		print " " unless ($suppress == 1 or $s =~ /^([.,\/;”:!?%})]|<[^>]+>)$/);
		$suppress = (($s =~ /^([“\/\$(\[#{]|<[^>]+>)$/) or ($s eq '"' and $ascii_double_quote_parity==1));
		if ($s eq $t) {
			print $s;
		}
		else {
			print $dispatch->{$ARGV[0]}->($s,$t);
			$suppress = 0;
		}
	}
}

exit 0;
