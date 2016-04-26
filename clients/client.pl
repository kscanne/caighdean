#!/usr/bin/perl
require 5.004;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use LWP::UserAgent;
use HTTP::Request::Common qw{ POST };
use JSON;
use Encode qw(decode);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";


sub xlate {
	(my $text, my $fns) = @_;
	my $ua = LWP::UserAgent->new();
	$ua->timeout(15);
    my $r = POST('https://borel.slu.edu/cgi-bin/seirbhis3.cgi',
				[ 'teacs' => $text, 'foinse' => $fns ]);
    my $response = $ua->request($r);
	if ($response->is_success) { 
	    my $arrayref;
		if (!defined(eval { $arrayref = from_json(decode('utf8',$response->content)) }) or
			!defined($arrayref) or ref($arrayref) ne 'ARRAY') {
			print STDERR "Didn't understand the response from the server\n";
		}
		else {
			#print decode('utf8',$response->content)."\n\n";
			my $t = '';
			for my $p (@{$arrayref}) {
				$t .= $p->[0].' => '.$p->[1]."\n";
			}
			return $t;
		}
	}
	else {
		print STDERR "There was a problem: ".$response->status_line."\n";
	}
	return undef;
}

die "Usage: perl client.pl [ga|gd|gv]" if (scalar @ARGV != 1);
my $foinse = $ARGV[0];
die "Usage: perl client.pl [ga|gd|gv]" unless ($foinse =~ m/^g[adv]$/);

my $slurp;
while (<STDIN>) {
	$slurp .= $_;
}

my $output = xlate($slurp, $foinse); 
print $output if (defined($output));

exit 0;
