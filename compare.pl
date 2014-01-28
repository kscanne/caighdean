#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my @pre;
my @post;

if ($#ARGV != 1) {
    die "Usage: $0 FILE1 FILE2\n";
}
my $threegrams1 = $ARGV[0];
my $threegrams2 = $ARGV[1];

sub normalize {
	(my $s) = @_;
	my $answer='';
	my $inword = 0;
	while ($s =~ /(.)/g) {
		my $c = $1;
		# easier to just split on all aposts
		#if ($c =~ /(\p{L}|[’'-])/) {
		if ($c =~ /(\p{L}|[-])/) {
			$answer .= $c;
			$inword = 1;
		}
		else {
			if ($inword) {
				$answer .= '|';
				$inword = 0;
			}
		}
	}
	#print STDERR "Warning: empty normalization: $s\n\n" if ($answer eq '');
	$answer = lc($answer);
	$answer =~ s/\|$//;
	return $answer;
}

open(PRE, "<:utf8", $ARGV[0]) or die "Could not open pre file: $!";
while (<PRE>) {
	chomp;
	push @pre, $_;
}
close PRE;

open(POST, "<:utf8", $ARGV[1]) or die "Could not open post file: $!";
while (<POST>) {
	chomp;
	push @post, $_;
}
close POST;

open(UNCHANGED, ">:utf8", "unchanged.txt") or die "Could not open output file unchanged.txt: $!";
open(PRETOKENS, ">:utf8", "pre-tokens.txt") or die "Could not open output file pre-tokens.txt: $!";
open(POSTTOKENS, ">:utf8", "post-tokens.txt") or die "Could not open output file post-tokens.txt: $!";



my $i = 0;
my $same = 0;
for my $preline (@pre) {
	my $postline = $post[$i];
	my $pre_norm = normalize($preline);
	my $post_norm = normalize($postline);
	if ($pre_norm eq $post_norm) {
		$same++;
		print UNCHANGED "$preline\n";
	}
	else {
		my @tokens = split(/\|/, $pre_norm);
		for my $t (@tokens) {
			print PRETOKENS "$t\n" unless ($t eq '');
		}
		@tokens = split(/\|/, $post_norm);
		for my $t (@tokens) {
			print POSTTOKENS "$t\n" unless ($t eq '');
		}
	}
	$i++;
}
#print "$same out of $i unchanged\n";

close UNCHANGED;
close PRETOKENS;
close POSTTOKENS;

exit 0;
