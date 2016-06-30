#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

if ($#ARGV != 0 or $ARGV[0] !~ m/^-[stfapr]$/) {
    die "Usage: $0 [-s|-t|-f|-a|-p|-r]\n  -s: source language only\n  -t: target language only\n  -f: focloir.ie NEID output\n  -a: mouseover annotations in HTML\n  -p: parallel text in HTML\n  -r: ruby text annotation";
}

# stuff for -p
my $opener='<td width="50%" valign="top"><div class="textcol">';
my $closer='</div></td>';
my $rhs=$opener;
my $counter=0;

my $dispatch = {
	'-s' => sub { (my $s, my $t) = @_; return $s; },
	'-t' => sub { (my $s, my $t) = @_; return $t; },
	'-f' => sub { (my $s, my $t) = @_; $t =~ s/ /_/g; return "^$s^ $t"; },
	'-a' => sub { (my $s, my $t) = @_; return "<span class=\"tooltip\">$s<span>$t</span></span>"; },
	'-p' => sub { (my $s, my $t) = @_; return "<label class=\"w$counter\">$s</label>"; },
	'-p2' => sub { (my $s, my $t) = @_; return "<label class=\"w$counter\">$t</label>"; },
	'-r' => sub { (my $s, my $t) = @_; return "<ruby><rb>$s</rb><rt>$t</rt></ruby>"; },
};
# set this flag true if no need for space before next token
# For example, start of doc, left parens, brackets
my $suppress = 1;
my $ascii_double_quote_parity = 0;

print "$opener\n" if ($ARGV[0] eq '-p');

# always assume format of input is the same as output of tiomanai.sh,
# i.e. a pair of source/target tokens separated by '=>' on each line
while (<STDIN>) {
	chomp;
	(my $s, my $t) = /^(.+) => (.+)$/;
	if ($s eq '\n') {
		$suppress = 1;
		print "\n";
		$rhs .= "\n";
	}
	else {
		if ($s eq '"') {
			$suppress = 1 if ($ascii_double_quote_parity==1);
			$ascii_double_quote_parity = 1 - $ascii_double_quote_parity;
		}
		unless ($suppress == 1 or $s =~ /^([\/%]|\p{Term}|\p{Pf}|\p{Pe}|<\/[^>]*>)$/) {
			print " ";
			$rhs .= " ";
		}
		$suppress = (($s =~ /^([\/\$#]|\p{Ps}|\p{Pi}|<[^\/>][^>]*>)$/) or ($s eq '"' and $ascii_double_quote_parity==1));
		if ($s eq $t) {
			print $s;
			$rhs .= $s;
		}
		else {
			print $dispatch->{$ARGV[0]}->($s,$t);
			$rhs .= $dispatch->{'-p2'}->($s,$t);
			$suppress = 0;
			$counter++;
		}
	}
}

if ($ARGV[0] eq '-p') {
	print "$closer\n$rhs\n$closer\n";
}

exit 0;
