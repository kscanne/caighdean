#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Memoize;
use DB_File;
use DBM_Filter;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $verbose = 0;
my $unknowns = 0;
my $extension = '';
my $db = 1;

for my $a (@ARGV) {
	$verbose = 1 if ($a eq '-v');
	$unknowns = 1 if ($a eq '-u');
	$extension = '-gd' if ($a eq '-d');
	$extension = '-gv' if ($a eq '-x');
}


my $maxdepth = 10;
my $penalty = 2.9;
my $tokens = 0;
my $unknown = 0;

my @rules;
my %spurious;
my %cands;
my %prob;
my %smooth;

sub max {
	(my $a, my $b) = @_;
	return $a if ($a > $b);
	return $b;
}

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

# argument is a hypothesis (so a hashref with 'logprob' and 'output' keys
sub hypothesis_pairs_string {
	(my $hyp) = @_;
	my $ans = '';
	for my $hr (@{$hyp->{'output'}}) {
		my $source = $hr->{'s'};
		my $target = $hr->{'t'};
		unless ($source eq $target) {
			$target = irishlc($target) unless ($source =~ m/_/);
			$target = recapitalize($target, cap_style($source));
			$source =~ s/([A-Za-zÀÈÌÒÙàèìòùáéíóúÁÉÍÓÚïçÇ'])_/$1 /g;
		}
		$ans .= "$source => $target\n";
	}
	return $ans;
}

# hard-coded N=3 here; "ngram" can come in either empty, a 1-gram, or 2-gram
# this function tacks on $w at the end, but pushes off first word
# in case $ngram starts out as a 2-gram
sub shift_ngram {
	(my $ngram, my $w) = @_;
	my $ans = $ngram;
	$ans .= ' ' unless ($ngram eq '');
	$ans .= $w;
	$ans =~ s/^[^ ]+ // if ($ngram =~ m/ /);
	return $ans;
}

sub recapitalize {
	(my $w, my $n) = @_;
	my $capital_p = $n % 2;
	$n = int($n / 2);
	my $firstcap_p = $n % 2;
	$n = int($n / 2);
	my $cap_after_hyphen = $n % 2;
	$n = int($n / 2);
	my $allcaps = $n % 2;
	if ($capital_p) {
		$w =~ s/^mc(.)/"Mc".uc($1)/e;
		$w =~ s/^o'(.)/"O'".uc($1)/e;
		$w =~ s/^mb/mB/;
		$w =~ s/^gc/gC/;
		$w =~ s/^nd/nD/;
		$w =~ s/^bhf/bhF/;
		$w =~ s/^ng/nG/;
		$w =~ s/^bp/bP/;
		$w =~ s/^ts/tS/;
		$w =~ s/^dt/dT/;
		$w =~ s/^([nt])-([aeiouáéíóú])/$1.uc($2)/e;
		unless ($firstcap_p) {
			$w =~ s/^([bdm]')([aeiouáéíóú])/$1.uc($2)/e;  # d'Éirinn
			$w =~ s/^(h-?)([aeiouáéíóú])/$1.uc($2)/e;  # hÉireann
		}
		unless ($w =~ /^[^ _]*\p{Lu}/) {
			$w =~ s/^(['-]*)(.)/$1.uc($2)/e;
		}
	}
	if ($cap_after_hyphen) {
		$w =~ s/-(.)/"-".uc($1)/eg;
	}
	if ($allcaps) {
		if ($w =~ m/\p{Ll}.*\p{Lu}/) {
			$w =~ s/^((?:\p{Ll}|['-])*\p{Lu})(.*)$/$1.uc($2)/e;
		}
		else {
			$w = uc($w);
		}
	}
	return $w;
}

# 1st bit: on if "first" letter capitalized (ignoring eclipsis, etc.)
# 2nd bit: on if the actual first letter is capitalized (Tacht but not tAcht)
# 3rd bit: on if there are any caps after hyphens (ignore initial h-,n-,t-)
# (only examples where it's mixed are like "Bhaile-an-Easa" - rare)
# 4rd bit: on if all caps (at least 2) after initial eclipsis or whatever.  So:
# 0 = fear, bean, droch-cheann
# 1 = bhFear, h-Árd-rí, 'Sé
# 3 = Droch-chor, Fear, Bean
# 4 = sean-Mháirtín
# 5 = bhFíor-Ghaedhealtacht
# 7 = Nua-Eabhrac, Ard-Easbog
# 9 = gCNOC
# 11 = FEAR 
# 13 = h-AIMSIRE
# 15 = SEAN-GHAEDHEAL
# It's important that this be reasonable on pre-standard text, so that
# h-Éireann is a "regular" capitalized word even w/ hyphen
sub cap_style {
	(my $w) = @_;
	my $ans = 0;
	$ans += 1 if ($w =~ m/^'*(([bdm]'|[hnt]-?)[AEIOUÁÉÍÓÚÀÈÌÒÙ]|mB|gC|n[DG]|bhF|bP|tS|dT|\p{Lu})/);
	$ans += 2 if ($w =~ m/^\p{Lu}/);
	$ans += 4 if ($w =~ m/^...*-\p{Lu}/);
	$ans += 8 if ($w =~ m/^'*(([hnt]-?)[AEIOUÁÉÍÓÚÀÈÌÒÙ]|mB|gC|n[DG]|bhF|bP|tS|dT)?(\p{Lu}|['-])*$/ and $w =~ /\p{Lu}.*\p{Lu}/);
	return $ans;
}

# same as gaeilge/crubadan/crubadan/tolow
sub irishlc {
	(my $w) = @_;
	return $w if ($w =~ /^[<\\]/);
	$w =~ s/^([nt])([AEIOUÁÉÍÓÚ])/$1-$2/;
	$w =~ s/ ([nt])([AEIOUÁÉÍÓÚ])/ $1-$2/g;
	return lc($w);
}

# whatever we do to corpus in gaeilge/ngram we need to do here!
# unicode apostrophes already handled at STDIN
sub ngram_preprocess {
	(my $w) = @_;
	$w = irishlc($w);
	$w =~ s/^[0-9]+$/<NUM>/;
	$w =~ s/^.{1001}.*$/<UNK>/;
	return $w;
}

# only called for n <= maximum stored in the precomputed lang model (usually 3)
# so generically, when called from compute_log_prob, we expect a string 
# say "X Y Z" as an arg, returns log P(Z | X Y).
# If arg is "X Y", we return P(Y | X), and for a word "X", P(X).
# When an ngram was not seen in training, we back off (recursion here)
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
			my $tail = $ngram;
			$tail =~ s/^[^ ]+ //;
			$ans = compute_log_prob_helper($tail);
			if (exists($smooth{$start})) {
				$ans += $smooth{$start};
			}
		}
		else {  # 1-gram
			$ans = $prob{'<UNSEEN>'};
		}
	}
	return $ans;
}

# conditional probability P(X|Y) of seeing k-gram $X
# (k generically == 1, but can be as big as biggest RHS in multi-xx)
# given preceding j-gram $Y (j is almost always == 2, except while
# processing the first couple of words of input, can be 0 or 1!)
# So "$Y $X" is what's in the source text...
sub compute_log_prob {
	(my $X, my $Y) = @_;
	my $ans = 0;
	$Y = '.' if ($Y eq '');
	while ($X =~ m/([^ ]+)/g) {
		my $w = $1;
		my $ngram = extend_sentence($Y, $w);
		$ans += compute_log_prob_helper($ngram);
		$Y = shift_ngram($Y, $w);
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
				next if (exists($spurious{"$w $a"}));
				if (exists($ans{$a})) {  # if already found some other way
					$ans{$a} = $subans->{$a} if ($subans->{$a} < $ans{$a});
				}
				else {
					$ans{$a} = $subans->{$a};
				}
			}
			# rule produces multiword: oidhche-sin => oidhche_sin
			if ($cand =~ m/^([^_]+)_(.+)$/ and scalar keys %ans == 0) {
				my $left = $1;
				my $right = $2;
				my $subans_l = all_matches($left, $subcount);
				my $subans_r = all_matches($right, $subcount);
				for my $a (keys %{$subans_l}) {
					for my $b (keys %{$subans_r}) {
						$ans{"$a $b"} = max($subans_l->{$a}, $subans_r->{$b});
					}
				}
			}
		}
	}
	return \%ans;
}

print "Loading rules file...\n" if $verbose;
open(RULES, "<:utf8", "rules$extension.txt") or die "Could not open spelling rules file: $!";
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

if ($db) {
	my $dbp = tie %prob, "DB_File", "prob.db", O_RDONLY, 0644, $DB_HASH or die "Cannot open prob.db: $!\n";
	$dbp->Filter_Push('utf8');

	my $dbs = tie %smooth, "DB_File", "smooth.db", O_RDONLY, 0644, $DB_HASH or die "Cannot open smooth.db: $!\n";
	$dbs->Filter_Push('utf8');

	memoize('compute_log_prob');
}
else {
	print "Loading n-gram language model...\n" if ($verbose);
	open(NGRAMS, "<:utf8", 'ngrams.txt') or die "Could not open n-gram data file ngrams.txt: $!";
	while (<NGRAMS>) {
		chomp;
		m/^(.+)\t(.+)\t(.+)$/;
		$prob{$1} = $2;
		$smooth{$1} = $3 unless ($3 == 0);
	}
	close NGRAMS;
}

memoize('all_matches');

# Keys are strings containing last two processed words, whether
# flushed or not.  If we haven't flushed in a while, the key is usually
# simply the last two words in the hypothesis.
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

# pass hashref in vs. using global %hypotheses
sub flush_best_hypothesis {
	(my $hashref) = @_;
	my $bestlogprob = -9999;
	my $bestkey;
	print "Flushing best of ".scalar(keys %{$hashref})." hypotheses\n" if ($verbose);
	for my $k (keys %{$hashref}) {
		if ($hashref->{$k}->{'logprob'} > $bestlogprob) {
			$bestlogprob = $hashref->{$k}->{'logprob'};
			$bestkey = $k;
		}
	}
	print "FLUSH:\n" if ($verbose);
	print hypothesis_pairs_string($hashref->{$bestkey}) unless ($unknowns);
	$hashref->{$bestkey} = {
		'logprob' => 0.0,
		'output' => [],
	}; 
}

sub process_ignorable_token {
	(my $tok) = @_;

	print "Processing ignorable: $tok\n" if $verbose;
	for my $two (keys %hypotheses) {
		push @{$hypotheses{$two}->{'output'}}, {'s' => $tok, 't' => $tok};
	}
}

sub process_one_token {
	(my $tok) = @_;

	$tokens++;
	my %newhypotheses;
	my $hashref = all_matches($tok, 0);
	my $unknown_p = (scalar keys %{$hashref} == 0);

	# if there were no matches in %cands, and none computed
	# by applying rules, then leave the token unchanged
	if ($unknown_p) {
		$hashref->{$tok} = 0;
		$unknown++;
		print "UNKNOWN: $tok\n" if $verbose;
		print "$tok\n" if $unknowns;
	}

	print "Input token = $tok\n" if $verbose;
	for my $x (keys %{$hashref}) {
		my $normalized_x = ngram_preprocess($x);
		print "Possible standardization: $x, normalized: $normalized_x\n" if $verbose;
		for my $two (keys %hypotheses) {
			my @newoutput = @{$hypotheses{$two}->{'output'}};
			push @newoutput, {'s' => $tok, 't' => $x};
			my $tail = extend_sentence($two, $normalized_x);
			my $candlogprob = compute_log_prob($normalized_x, $two);
			my %newhyp = (
				'logprob' => $hypotheses{$two}->{'logprob'} + $candlogprob - $penalty*$hashref->{$x},
				'output' => \@newoutput,
			);
			if ($verbose) {
				print "Created a new hypothesis (".$newhyp{'logprob'}."): ".hypothesis_output_string(\%newhyp)."\n";
				print "Computed from logprob of best hypothesis with key $two: ".$hypotheses{$two}->{'logprob'}."\n";
				print "Plus logprob of n-gram: $tail ($candlogprob)\n";
				print "Minus penalty $penalty times ".$hashref->{$x}."\n";
			}
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
	flush_best_hypothesis(\%newhypotheses) if (scalar keys %newhypotheses == 1);
	%hypotheses = %newhypotheses;

	if ($verbose) {
		print "Live hypotheses:\n";
		for my $two (keys %hypotheses) {
			print "Hypothesis with key '$two' (".$hypotheses{$two}->{'logprob'}."): ".hypothesis_output_string($hypotheses{$two})."\n";
		}
	}
	# when evaluating, don't want to memoize the fake answer for unknown tokens
	delete $hashref->{$tok} if (($verbose or $unknowns) and $unknown_p);
}

print "Ready.\n" if $verbose;
while (<STDIN>) {
	chomp;
	if (/[a-zA-ZáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙ]/) {
		s/[ʼ’]/'/g;
		s/[‐‑]/-/g;  # U+2010, U+2011 to ASCII
	}
	if ($_ eq '\n' or /[<>:@&;=,.]/) { # skip SGML markup, newlines, URLs, etc.
		process_ignorable_token($_);
	}
	elsif (/^'/ or /'$/) {
		if (exists($cands{$_}) or /^'+$/ or
			(/^'*[A-ZÁÉÍÓÚÀÈÌÒÙ]/ and exists($cands{lc($_)}))) {
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

flush_best_hypothesis(\%hypotheses);

if ($verbose) {
	print "Total tokens: $tokens\n";
	print "Unknown tokens: $unknown\n";
	if ($tokens > 0) {
		my $frac = $unknown / (1.0 * $tokens);
		print "Fraction unknown: $frac\n";
	}
}

exit 0;
