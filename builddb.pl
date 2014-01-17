#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use DB_File;
use DBM_Filter;


unlink "prob.db";
my $dbp = tie my %prob, "DB_File", "prob.db", O_RDWR|O_CREAT, 0644, $DB_HASH or die "Cannot open prob.db: $!\n";
$dbp->Filter_Push('utf8');

unlink "smooth.db";
my $dbs = tie my %smooth, "DB_File", "smooth.db", O_RDWR|O_CREAT, 0644, $DB_HASH or die "Cannot open smooth.db: $!\n";
$dbs->Filter_Push('utf8');

open(NGRAMS, "<:utf8", 'ngrams.txt') or die "Could not open ngrams.txt: $!";
while (<NGRAMS>) {
	chomp;
	m/^(.+)\t(.+)\t(.+)$/;
	$prob{$1} = $2;
	$smooth{$1} = $3 unless ($3 == 0);
	print "$.\n" if ($. % 1000000 == 0);
}
close NGRAMS;

untie %prob;
untie %smooth;
exit 0;
