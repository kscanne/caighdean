#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Storable;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $verbose = 0;
my $extension = '';

for my $a (@ARGV) {
	$verbose = 1 if ($a eq '-v');
	$extension = '-gd' if ($a eq '-d');
	$extension = '-gv' if ($a eq '-x');
}

my %spurious;
my %cands;

sub irishlc {
	(my $w) = @_;
	$w =~ s/^([nt])([AEIOUÁÉÍÓÚ])/$1-$2/;
	$w =~ s/ ([nt])([AEIOUÁÉÍÓÚ])/ $1-$2/g;
	return lc($w);
}

print "Loading spurious pairs...\n" if $verbose;
open(SPURIOUS, "<:utf8", "spurious$extension.txt") or die "Could not open list of spurious pairs: $!";
while (<SPURIOUS>) {
	chomp;
	$spurious{$_}++;
}
close SPURIOUS;

print "Loading clean word list...\n" if $verbose;
open(CLEAN, "<:utf8", "clean.txt") or die "Could not open clean wordlist: $!";
while (<CLEAN>) {
	chomp;
	push @{$cands{$_}}, $_ unless (exists($spurious{"$_ $_"}));
}
close CLEAN;

print "Loading list of pairs...\n" if $verbose;
open(PAIRS, "<:utf8", "pairs$extension.txt") or die "Could not open list of pairs: $!";
while (<PAIRS>) {
	chomp;
	next if exists($spurious{$_});
	m/^([^ ]+) (.+)$/;
	push @{$cands{$1}}, $2;
}
close PAIRS;

print "Loading multi-word phrase pairs...\n" if $verbose;
open(MULTI, "<:utf8", "multi$extension.txt") or die "Could not open list of phrases: $!";
while (<MULTI>) {
	chomp;
	m/^([^ ]+) (.+)$/;
	my $source = $1;
	my $target = $2;
	push @{$cands{$source}}, $target;
	if ($source =~ m/\p{Lu}/) {
		push @{$cands{lc($source)}}, irishlc($target);
	}
}
close MULTI;

print "Loading local pairs...\n" if $verbose;
open(LOCALPAIRS, "<:utf8", "pairs-local$extension.txt") or die "Could not open list of local pairs: $!";
while (<LOCALPAIRS>) {
	chomp;
	if (exists($spurious{$_})) {
		print STDERR "Warning: pair \"$_\" is in pairs-local and spurious\n"; 	
	}
	m/^([^ ]+) (.+)$/;
	push @{$cands{$1}}, $2;
}
close LOCALPAIRS;

store \%cands, "cands$extension.hash";

exit 0;
