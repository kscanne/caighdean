#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Memoize;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $verbose = 0;

if ($#ARGV == 0 and $ARGV[0] eq '-v') {
	$verbose = 1;
}

my $maxdepth = 10;
my $penalty = 2.9;

my @rules;
my %cands;
my %prob;
my %smooth;

sub extend_sentence {
	(my $s, my $w) = @_;
	return $w if ($s eq '');
	return "$s $w";
}

sub last_two_words {
	(my $s) = @_;
	if ($s =~ m/ /) {
		$s =~ m/([^ ]+ [^ ]+)$/;
		return $1;
	}
	else {
		return $s;
	}
}

sub hypothesis_output_string {
	(my $hyp) = @_;
	my $ans = '';
	for my $hr (@{$hyp->{'output'}}) {
		$ans .= $hr->{'t'}." ";
	}
	$ans =~ s/ $//;
	return $ans;
}

sub hypothesis_pairs_string {
	(my $hyp) = @_;
	my $ans = '';
	for my $hr (@{$hyp->{'output'}}) {
		$ans .= $hr->{'s'}." => ".$hr->{'t'}."\n";
	}
	return $ans;
}

sub shift_ngram {
	(my $ngram, my $w) = @_;
	return $w if ($ngram eq '');
	$ngram =~ s/^[^ ]+ //;
	return "$ngram $w";
}

# takes an n-gram, say "X Y Z" as an arg, returns log P(Z | X Y)
# recursive for unseen n-grams, n > 1 
# only called for n <= maximum stored in the precomputed lang model (usually 3)
sub compute_log_prob_helper {
	(my $ngram) = @_;
	my $ans;
	if (exists($prob{$ngram})) {
		$ans = $prob{$ngram};
	}
	else {
		if ($ngram =~ m/ /) {  # n>1
			my $start = $ngram;
			$start =~ s/ [^ ]+$//;
			if (exists($smooth{$start})) {
				my $tail = $ngram;
				$tail =~ s/^[^ ]+ //;
				$ans = compute_log_prob_helper($tail) + $smooth{$start};
			}
			else {
				$ngram =~ m/([^ ]+)$/;
				$ans = compute_log_prob_helper($1);
			}
		}
		else {  # 1-gram
			$ans = $prob{'<UNSEEN>'};
		}
	}
	return $ans;
}

sub compute_log_prob {
	(my $ngram) = @_;
	my $ans = 0;
	if ($ngram =~ m/^([^ ]+ [^ ]+ [^ ]+) [^ ]/) {
		my $initial = $1;
		$ans += compute_log_prob_helper($initial);
		$ngram =~ s/^[^ ]+ [^ ]+ [^ ]+ //;
		while ($ngram =~ m/([^ ]+)/g) {
			$initial = shift_ngram($initial, $1);
			$ans += compute_log_prob_helper($initial);
		}
	}
	else {
		$ans = compute_log_prob_helper($ngram);
	}
	return $ans;
}

# takes non-standard word and returns hashref whose keys are
# candidate standardizations and values the number of rules applied to get there
# Second argument is there because it's recursive.
# Callers should call as: all_matches('focal', 0)
sub all_matches {
	(my $w, my $count) = @_;
	my %ans;
	return \%ans if ($count > $maxdepth);
	if (exists($cands{$w})) {
		for my $std (@{$cands{$w}}) {
			if ($std eq $w) {
				$ans{$std} = $count;
			}
			else {
				$ans{$std} = $count + 1;
			}
		}
	}
	for my $rule (@rules) {
		my $p = $rule->{'patt'};
		if ($w =~ m/$p/) {
			my $r = $rule->{'repl'};
			my $cand = $w;
			$cand =~ s/$p/$r/eeg;
			my $subcount = $count;
			$subcount++ unless ($rule->{'level'} == -1);
			my $subans = all_matches($cand, $subcount);
			for my $a (keys %{$subans}) {
				if (exists($ans{$a})) {  # if already found some other way
					if ($subans->{$a} < $ans{$a}) {
						$ans{$a} = $subans->{$a};
					}
				}
				else {
					$ans{$a} = $subans->{$a};
				}
			}
		}
	}
	return \%ans;
}

print "Loading rules file...\n" if $verbose;
open(RULES, "<:utf8", "rules.txt") or die "Could not open morph rules file: $!";
while (<RULES>) {
	next if (/^#/);
	chomp;
	my %rule;
	m/^(\S+)\t(\S+)\t([0-9-]+)$/;
	$rule{'patt'} = qr/$1/;
	$rule{'level'} = $3;
	my $repl = $2;
	$repl =~ s/(.+)/"$1"/;
	$rule{'repl'} = $repl;
	push @rules, \%rule;
}
close RULES;

print "Loading clean word list...\n" if $verbose;
open(CLEAN, "<:utf8", "clean.txt") or die "Could not open clean wordlist: $!";
while (<CLEAN>) {
	chomp;
	push @{$cands{$_}}, $_;
}
close CLEAN;

my %spurious;
print "Loading spurious non-standard/standard...\n" if $verbose;
open(SPURIOUS, "<:utf8", "spurious.txt") or die "Could not open list of spurious pairs: $!";
while (<SPURIOUS>) {
	chomp;
	$spurious{$_}++;
}
close SPURIOUS;

print "Loading non-standard/standard pairs...\n" if $verbose;
open(PAIRS, "<:utf8", "pairs.txt") or die "Could not open list of pairs: $!";
while (<PAIRS>) {
	chomp;
	next if exists($spurious{$_});
	m/^([^ ]+) (.+)$/;
	push @{$cands{$1}}, $2;
}
close PAIRS;

print "Loading local non-standard/standard pairs...\n" if $verbose;
open(LOCALPAIRS, "<:utf8", "pairs-local.txt") or die "Could not open list of local pairs: $!";
while (<LOCALPAIRS>) {
	chomp;
	if (exists($spurious{$_})) {
		print STDERR "Warning: pair \"$_\" is in pairs-local and spurious\n"; 	
	}
	m/^([^ ]+) (.+)$/;
	push @{$cands{$1}}, $2;
}
close LOCALPAIRS;

print "Loading n-gram language model...\n" if $verbose;
open(NGRAMS, "<:utf8", "ngrams.txt") or die "Could not open n-gram data: $!";
while (<NGRAMS>) {
	chomp;
	m/^(.+)\t(.+)\t(.+)$/;
	$prob{$1} = $2;
	$smooth{$1} = $3 unless ($3 == 0);
}
close NGRAMS;

memoize('all_matches');

# Keys are strings containing last two words in the hypothesis.
# We just need the last two since these are used to compute the
# most likely *next* word, which only depends on the previous two.
# The value corresponding to the two words is a hashref representing
# the *best* hypothesis with the given two final words.
# The hashref stores the running logprob of the hypothesis
# and an array containing all of the standardizations in the hypothesis...
# this could conceivably be quite long.
# entries in the array are hashrefs that look like:
# {'s' => 'bainríoghan', 't' => 'banríon'}
my %hypotheses;
$hypotheses{''} = {
	'logprob' => 0.0,
	'output' => [],
}; 

sub process_one_token {
	(my $tok) = @_;

	my %newhypotheses;
	my $hashref = all_matches($tok, 0);

	# if there were no matches in %cands, and none computed
	# by applying rules, then leave the token unchanged
	if (scalar keys %{$hashref} == 0) {
		$hashref->{$tok} = 0;
	}

	print "Input token = $tok\n" if $verbose;
	for my $x (keys %{$hashref}) {
		print "Possible standardization: $x\n" if $verbose;
		for my $two (keys %hypotheses) {
			my @newoutput = @{$hypotheses{$two}->{'output'}};
			push @newoutput, {'s' => $tok, 't' => $x};
			my $tail = extend_sentence($two, $x);
			my %newhyp = (
				'logprob' => $hypotheses{$two}->{'logprob'} + compute_log_prob($tail) - $penalty*$hashref->{$x},
				'output' => \@newoutput,
			);
			print "Created a new hypothesis (".$newhyp{'logprob'}."): ".hypothesis_output_string(\%newhyp)."\n" if $verbose;
			my $newtwo = last_two_words($tail);
			if (exists($newhypotheses{$newtwo})) {
				# need only keep the best among those ending w/ these two words
				if ($newhypotheses{$newtwo}->{'logprob'} < $newhyp{'logprob'}) {
					$newhypotheses{$newtwo} = \%newhyp;
					print "And it's the best so far ending in: $newtwo\n" if $verbose;
				}
				else {
					print "But not as good as (".$newhypotheses{$newtwo}->{'logprob'}."): ".hypothesis_output_string($newhypotheses{$newtwo})."\n" if $verbose;
				}
			}
			else {
				$newhypotheses{$newtwo} = \%newhyp;
				print "And it's the first (hence best) so far ending in: $newtwo\n" if $verbose;
			}
		}
	}

	# if there's only one hypothesis left, we can flush output and reset
	if (scalar keys %newhypotheses == 1) {
		my $uniq = (keys %newhypotheses)[0];
		print "FLUSH:\n" if ($verbose);
		print hypothesis_pairs_string($newhypotheses{$uniq});
		delete $newhypotheses{$uniq};
		$newhypotheses{''} = {
			'logprob' => 0.0,
			'output' => [],
		}; 
	}
	%hypotheses = %newhypotheses;
	if ($verbose) {
		print "Live hypotheses:\n";
		my $counter = 1;
		for my $two (keys %hypotheses) {
			print "Hypothesis $counter (".$hypotheses{$two}->{'logprob'}."): ".hypothesis_output_string($hypotheses{$two})."\n";
			$counter++;
		}
	}
}

print "Ready.\n" if $verbose;
while (<STDIN>) {
	chomp;
	if (/^'/ or /'$/) {
		if (exists($cands{$_}) or /^'+$/) {
			process_one_token($_);
		}
		else {
			m/^('*)(.*[^'])('*)$/;
			process_one_token($1) if ($1 ne '');
			process_one_token($2) if ($2 ne '');
			process_one_token($3) if ($3 ne '');
		}
	}
	else {
		process_one_token($_);
	}
}

exit 0;
