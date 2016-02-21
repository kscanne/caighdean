#!/usr/bin/perl
# Usage: cat file.txt | alltokens.pl "'-" "A-Za-z"
# first argument is a string of 'interior-only' characters
# second argument is a string of characters that we grep for

use strict;
use warnings;
use Encode qw(decode);
use Unicode::Normalize;

if ($#ARGV != 1) {
    die "Usage: $0 interiorcharstring bdcharstring\n";
}
@ARGV = map { NFC(decode('utf-8', $_)) } @ARGV;
my $ints = $ARGV[0];
my $bdstr = $ARGV[1];

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# probably want to sync these with filt.pl
# (good way of cleaning corpus is to kill sentences with these!)
my @fixed = (
	qr/(?:https?|ftp):\/\/[A-Za-z0-9\/.:=_%?&~+;\$@\#()-]+[A-Za-z0-9\/=]/, # URLs
	qr/[A-Za-z0-9._]+@[A-Za-z0-9.]+[A-Za-z0-9]/,   # emails
	qr/&(amp|[lg]t|quot|#[0-9]+);/, # SGML entities
	qr/<[\/]?[A-Za-z]([^>]+)?>/,             # markup
	qr/[:;=]['’0o-]?[()\]\\{}|dpDP][)]*/,  # emoticons
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
	for my $patt (@fixed) {
		s/($patt)/\n$1\n/sg;
	}
	my @chunks = split /\n/;
	for my $chunk (@chunks) {
		my $fixed_p = 0;
		for my $patt (@fixed) {
			if ($chunk =~ /$patt/) { 
				print "$chunk\n";
				$fixed_p = 1;
				last;
			}
		}
		process_chunk($chunk) unless ($fixed_p);
	}
	print '\n'."\n";
}
exit 0;
