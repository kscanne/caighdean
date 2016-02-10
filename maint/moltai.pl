#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my @all;
my %suffixes;
my %prefixes;

while (<STDIN>) {
	chomp;
	my $curr = $_;
	push @all, $curr;
	(my $foinse, my $sprioc) = $curr =~ m/^([^ ]+) (.+)$/;
	my $temp = $foinse;
	push @{$prefixes{$temp}}, $curr;
	while ($temp =~ m/_/) {
		$temp =~ s/_[^_]+$//;
		push @{$prefixes{$temp}}, $curr;
	}
	$temp = $foinse;
	push @{$suffixes{$temp}}, $curr;
	while ($temp =~ m/_/) {
		$temp =~ s/^[^_]+_//;
		push @{$suffixes{$temp}}, $curr;
	}
}

sub print_suffix_matches {
	(my $cand, my $full) = @_;
	if (exists($suffixes{$cand})) {
		for my $iomlan (@{$suffixes{$cand}}) {
			my $f = $iomlan;
			$f =~ s/ .+$//;
			unless ($full =~ m/^$f /) {
				print "$iomlan\n$full\n\n";
			}
		}
	}
}

sub print_prefix_matches {
	(my $cand, my $full) = @_;
	if (exists($prefixes{$cand})) {
		for my $iomlan (@{$prefixes{$cand}}) {
			my $f = $iomlan;
			$f =~ s/ .+$//;
			unless ($full =~ m/^$f /) {
				print "$full\n$iomlan\n\n";
			}
		}
	}
}


for my $curr (@all) {
	(my $foinse, my $sprioc) = $curr =~ m/^([^ ]+) (.+)$/;
	my $temp = $foinse;
	print_suffix_matches($temp, $curr);
	while ($temp =~ m/_/) {
		$temp =~ s/_[^_]+$//;
		print_suffix_matches($temp, $curr);
	}
	$temp = $foinse;
	print_prefix_matches($temp, $curr);
	while ($temp =~ m/_/) {
		$temp =~ s/^[^_]+_//;
		print_prefix_matches($temp, $curr);
	}
}

exit 0;
