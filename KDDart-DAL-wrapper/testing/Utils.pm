package Utils;
require Exporter;

use strict;
use warnings;

use JSON;
use Try::Tiny;
my $j = JSON->new;

our @ISA      = qw(Exporter);
our @EXPORT   = qw( onError readConfig );

# --------------

# onError($messageText, $errorText);
sub onError {
	print "ERROR: " . $_[1] . "\n";
	print "DAL response: \n" . $_[0] . "\n\n";
	exit 1;
}

# --------------

# my $CONFIG = readConfig();
sub readConfig {
	open(CONF, "<", "config.json") or die "Could not read config file\n";
	my @lines = <CONF>;
	close CONF;
	
	my $jsonstr = join('', @lines);
	
	my $CONFIG;
	try {
		$CONFIG = $j->decode($jsonstr);
	} catch {
		print "Error in config file - probably not properly formatted\n";
		exit 1;
	};
	
	return $CONFIG;
}

1;