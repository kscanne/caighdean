#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Redis;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $prune = 0;  # don't write out n-grams with count <= than this
my $verbose = 1;
my $redis = Redis->new;  # 127.0.0.1:6379

# the two tables we're trying to compute
# these will only be used to store results for n < N
# and for n==N we write directly to Redis DB
my %prob;
my %smooth;

my %total;  # keys are lengths, value is total number of n-grams of that length (*not* unique)
my %uniq;  # keys are lengths, value is total number of unique n-grams of that length
my %hapax;  # keys are lengths, values are number of n-grams of that length appearing exactly once in training
my %dis;    # keys are lengths, values are number of n-grams of that length appearing exactly twice in training
my %discount; # keys are lengths, values are "discounts" subtracted from the n-gram count for that length in computing interpolated probability; see eqs. 18 and 19 in Chen and Goodman
my %followers; # keys are n-grams, vals are number of distinct n+1-grams which begin with the given n-gram
my %lowercounts;  # keys are n-grams (1 <= n < N), vals are raw counts
my $unseen = '<UNSEEN>';


if ($#ARGV != 0) {
        die "Usage: perl buildmodel.pl N\n";
}
my $N = $ARGV[0];
if ($N < 1) {
        die "Only N>=1 allowed";
}

# count total number of each order, hapax, etc.
for my $n (1..$N) {
	print STDERR "Counting $n-grams, hapax, etc...\n" if $verbose;
	$total{$n} = 0;
	my $total = 0;
	open(COUNTS, "<:utf8", "training-$n.txt") or die "Could not open training data for n=$n";
	while (<COUNTS>) {
		chomp;
		(my $count, my $k) = m/^([0-9]+) (.+)$/;
		$hapax{$n}++ if ($count == 1);
		$dis{$n}++ if ($count == 2);
		$total{$n} += $count;
		$uniq{$n} += 1;
		$lowercounts{$k} = $count if ($n < $N);
		print STDERR "WARNING: $n-gram with count zero!\n" if ($count == 0);
	}
	close COUNTS;
}

print STDERR "Computing discounts...\n" if $verbose;
# compute discounts
for my $n (2..$N) {
	if ($hapax{$n} + $dis{$n} > 0) {
		# estimate from Ney, Essen, Kneser 1994
		$discount{$n} = $hapax{$n} / ($hapax{$n} + 2*$dis{$n});
	}
	else {
		print STDERR "WARNING: For n=$n, no hapax or dis legomenon\n";
		$discount{$n} = 0;
	}
}

print STDERR "Computing 1-gram probs...\n" if $verbose;
# compute 1-gram probs
$prob{$unseen} = 0.5/$total{'1'};
$smooth{$unseen} = 1;
open(COUNTS, "<:utf8", "training-1.txt") or die "Could not open training data for n=1";
while (<COUNTS>) {
	chomp;
	(my $v, my $k) = m/^([0-9]+) (.+)$/;
	$prob{$k} = $v / $total{'1'};
}
close COUNTS;

print STDERR "Computing unique followers...\n" if $verbose;
# compute number of unique "followers" for each n-gram
for my $n (2..$N) {
	print STDERR "Computing unique followers by examining $n-grams...\n" if $verbose;
	open(COUNTS, "<:utf8", "training-$n.txt") or die "Could not open training data for n=$n";
	while (<COUNTS>) {
		chomp;
		my $k = $_;
		$k =~ s/^[0-9]+ //;
		my $start = $k;
		$start =~ s/ [^ ]+$//;
		$followers{$start}++;
	}
	close COUNTS;
}

# compute smoothing parameters for all possible initial (n-1)-grams
for (my $n = 1; $n < $N; $n++) {
	print STDERR "Computing smoothing params for n=$n...\n" if $verbose;
	open(COUNTS, "<:utf8", "training-$n.txt") or die "Could not open training data for n=$n";
	while (<COUNTS>) {
		chomp;
		(my $rawcount, my $k) = m/^([0-9]+) (.+)$/;
		my $f = 1;
		# only doesn't exist for last (n-1)-gram in whole corpus
		# (and not even always in that case)
		$f = $followers{$k} if (exists($followers{$k}));
		$smooth{$k} = $discount{$n + 1} * $f / $rawcount;
	}
	close COUNTS;
}

# interpolated higher order probabilites
# important to do these in order of increasing n, since
# prob of any n-gram depends on the prob of it's (n-1)-gram tail.
for my $n (2..$N) {
	my $iom = $uniq{$n};
	my $percent = int($iom/100);
	my $ct = 0;
	print STDERR "Computing $iom $n-gram probs...\n" if $verbose;
	open(COUNTS, "<:utf8", "training-$n.txt") or die "Could not open training data for n=$n";
	while (<COUNTS>) {
		chomp;
		(my $rawcount, my $k) = m/^([0-9]+) (.+)$/;
		print int($ct/$percent)."%...\n" if ($verbose and $ct % $percent == 0);
		$ct++;
		my $start = $k;
		$start =~ s/ [^ ]+$//;
		my $startcount = $lowercounts{$start};
		my $tail = $k;
		$tail =~ s/^[^ ]+ //;
		my $newprob = (($rawcount - $discount{$n}) / $startcount) + $smooth{$start} * $prob{$tail};
		if ($n == $N and $rawcount > $prune) { # write highest order ones directly to DB
			my $v = sprintf("%.3f", log($newprob));
			$redis->set($k => $v);
		}
		else {  # we'll keep lower order ones in perl hash
			$prob{$k} = $newprob
		}
	}
	close COUNTS;
}

$lowercounts{$unseen} = $prune+1;
print STDERR "Take log of lower-order probs and write to DB...\n" if $verbose;
for my $k (keys %prob) {
	if ($lowercounts{$k} > $prune) {
		my $probout = sprintf("%.3f", log($prob{$k}));
		$redis->set($k => $probout);
	}
}
print STDERR "Writing smoothing constants to DB...\n" if $verbose;
$redis->select(1);
for my $k (keys %smooth) {
	if ($lowercounts{$k} > $prune) {
		my $smoothout = sprintf("%.3f", log($smooth{$k}));
		$redis->set($k => $smoothout);
	}
}

exit 0;
