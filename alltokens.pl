#!/usr/bin/perl
# Usage: cat file.txt | alltokens.pl "'-" "A-Za-z"
# first argument is a string of 'interior-only' characters
# second argument is a string of characters that we grep for

use strict;
use warnings;
use Encode qw(decode);
use Unicode::Normalize;
use utf8;

if ($#ARGV != 1) {
    die "Usage: $0 interiorcharstring bdcharstring\n";
}
@ARGV = map { NFC(decode('utf-8', $_)) } @ARGV;
my $ints = $ARGV[0];
my $bdstr = $ARGV[1];

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $emoji = '\x{0023}\x{002A}-\x{0039}\x{00A9}\x{00AE}\x{203C}\x{2049}\x{2122}-\x{2B55}\x{1F004}-\x{1FAF6}';
my $skintone = '\x{1F3FB}-\x{1F3FF}';

# probably want to sync these with filt.pl
# (good way of cleaning corpus is to kill sentences with these!)
my @fixed = (
	qr/<[\/]?[A-Za-z]([^>]+)?>/,             # markup
	qr/(?:https?|ftp):\/\/[A-ZÁÉÍÓÚa-záéíóú0-9\/.:=_%?&~+;\$@\#()-]+[A-ZÁÉÍÓÚa-záéíóú0-9\/=]/, # URLs
	qr/[A-Za-z0-9][A-Za-z0-9._]*@[A-Za-z0-9.]+[A-Za-z0-9]/,   # emails
	qr/(?:www\.)?([A-ZÁÉÍÓÚa-záéíóú0-9-]+\.){1,3}(?:blog|ca|com|ed?u|i[em]|info|net|org|scot|(?:org|gov|co|ac)\.uk)/, # URLs w/o protocol
	qr/&([A-Za-z.]+|#[0-9]+);/, # SGML entities &amp; &quot; &#2020; etc.
	qr/%([0-9]\$)?[A-Za-z]+/, # l10n vars, %1$S, %S, %d, %lu, etc.
	qr/[:;=]['’0o-]?[()\]\\{}|dpDP][)]*/,  # emoticons
	qr/[$emoji][$skintone]?(\x{200D}[$emoji][$skintone]?)+[\x{FE0E}\x{FE0F}]?/,  # non-trivial ZWJ sequences
	qr/[$emoji][\x{FE0E}\x{FE0F}]/,  # emoji with variation selector
	qr/[\x{1F1E6}-\x{1F1FF}][\x{1F1E6}-\x{1F1FF}]/, # flags
	qr/[\x{261D}\x{26F9}-\x{270D}\x{1F385}-\x{1F9DD}][$skintone]/, # skin-tone modified emoji but no ZWJ sequence
	qr/[1-9][0-9]{0,2}(?:,[0-9]{3})+(?:\.[0-9]+)?/,  # numbers with commas in them
	qr/(?<![,0-9])[0-9]+(?:[:.][0-9]+)+/,  # times: 6:45 11.30, IP addresses, etc.; negative lookbehind prevents this from breaking up token "5,000.00" found by previous regex
);

my $curr='';
my $toktype=0; # 0=word, 1=number, 2=other (punc, etc.)

sub flushcurr {
	if ($curr ne '') {
		if ($toktype==0) {
			# first block is pair of balanced parens, but not initial/final
			# e.g. analytic(al)
			if ($curr =~ m/^..*\(.+\)/ or $curr =~ m/\(.+\).*.$/) {
				print "$curr\n";
				$curr = '';
				return;
			}
			if ($curr =~ m/^([(]+)([^()]*[)]?)$/) {  # "(Don't" or "(good)"
				print "$1\n";
				$curr = $2;
			}
			if ($ints eq '') {
				print "$curr\n" unless ($curr eq '');
			}
			else {
				(my $post) = $curr =~ m/([$ints]*)$/;
				$curr =~ s/([$ints]*)$//;
				print "$curr\n" unless ($curr eq '');
				while ($post =~ /(.)/g) {
					print "$1\n";
				}
			}
		}
		else {
			print "$curr\n";
		}
		$curr = '';
	}
}

# usually a line, or chunk between URLs, email addresses, etc.
sub process_chunk {
	(my $chunk) = @_;
    while ($chunk =~ /(.)/gs) {
        my $c=$1;
        if ($c =~ /^([\x{200C}\x{200D}\x{055A}\x{055B}\x{055C}\x{055E}]|\p{L}|\p{M}|[$bdstr])$/) {
			flushcurr() unless ($toktype==0);
			$toktype=0;
        }
        elsif ($ints ne '' and $c =~ /^[$ints]$/) {
			unless ($toktype==0 and $curr ne '' and $curr !~ m/[$ints]$/) {
				flushcurr();
				$toktype=2;
			}
			# if toktype==0 and curr is non-empty, then do nothing, toktype
			# remains 0 and append the intchar to curr
		}
		elsif ($c =~ /^[0-9]$/) {  # won't get here if 0-9 are bdchars for lang
			flushcurr() unless ($toktype==1);
			$toktype=1;
		}
        else {
			flushcurr();
			$toktype=2;
        }
		$curr .= $c unless ($c =~ /^\s$/);
    }
	flushcurr();
	$toktype = 0;
}

while (<STDIN>) {
	my $newline_p = /\n$/;

	# first part of each iteration converts the current line into
	# a linked list of nodes, each representing a "chunk" of the line
	# where a chunk consists of either a token matching one of the
	# regexen in @fixed, or some substring in between those fixed tokens
	# The point is that we want to apply these in order, and once we 
	# find a fixed token (an HTML tag, say), we don't want to look for
	# the later patterns within it (URLs, say)
	my %head = (
		'string' => $_,
		'fixed_p' => 0,
		'next' => 0,
	);
	my $currnode;
	for my $patt (@fixed) {
		$currnode = \%head;
		while ($currnode != 0) {
			my $currstr = $currnode->{'string'};
			if ($currnode->{'fixed_p'}==0 and $currstr =~ /$patt/) {
				my $nextnode = $currnode->{'next'};
				$currstr =~ s/($patt)/\n$1\n/sg;
				my @chunks = split(/\n/,$currstr);
				my $first = shift @chunks;
				$currnode->{'string'} = $first;
				$currnode->{'fixed_p'} = 1 if ($first =~ /$patt/);
				for my $chunk (@chunks) {
					unless ($chunk eq '') {
						my %node = (
							'string' => $chunk,
							'fixed_p' => 0,
							'next' => $nextnode,
						);
						$node{'fixed_p'} = 1 if ($chunk =~ /$patt/);
						$currnode->{'next'} = \%node;
						$currnode = $currnode->{'next'};
					}
				}
			}
			$currnode = $currnode->{'next'};
		}
	}

	# the remainder iterates over the linked list, outputting the fixed
	# tokens as they are, and passing the others to process_chunk for
	# further decompsition into words, etc.
	$currnode = \%head;
	while ($currnode != 0) {
		if ($currnode->{'fixed_p'}==1) {
			print $currnode->{'string'}."\n";
		}
		else {
			process_chunk($currnode->{'string'});
		}
		$currnode = $currnode->{'next'};
	}
	print '\n'."\n" if $newline_p;
}
exit 0;
