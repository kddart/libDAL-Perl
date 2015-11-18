#!/usr/bin/perl -w

# =========================================================== #
# Grzegorz Uszynski (2015-06-12)
# version 1.0
# KDDart login using KDDart::DAL::wrapper library
# =========================================================== #

use strict;
use KDDart::DAL::wrapper;
use Data::Dumper;

use Utils;

my $CONFIG = readConfig();

# SETUP your run
my $dalbase      = $CONFIG->{baseurl};
my $user         = $CONFIG->{username};
my $pass         = $CONFIG->{password};
my $group        = $CONFIG->{groupid};
my $cookiefolder = $CONFIG->{cookiefolder};
my $cookiefile   = $CONFIG->{cookiefile};

my %options = ();
if ($cookiefile) { $options{cookiefile} = $cookiefile; }

if ($cookiefolder) { $options{cookiefolder} = $cookiefolder; }

# build an object (only baseurl is required)
my $DALobj = KDDart::DAL::wrapper->new( baseurl => $dalbase, verbose => 1, autogroupswitch => 1, extradata => 0, %options );
&onError("problem with object creation", $DALobj->errormsg) if $DALobj->error;

my $randomstr = $DALobj->_makeRandomString( -len => 12 );

print "

# starting the run #
current base url: " . $DALobj->baseurl . "
random string:    " . $randomstr . "
";

# login into DAL
my $result = $DALobj->DALlogin( username => $user, password => $pass, passwordcleartext => 1 );
&onError($result, $DALobj->errormsg) if $DALobj->error;

print "
# user login #
write token:      " . $DALobj->writetoken . "
username:         " . $DALobj->username . "
userid:           " . $DALobj->userid . "

# group auto switch to first available group #
groupname:        " . $DALobj->groupname . "
groupid:          " . $DALobj->groupid . "
group manager:    " . $DALobj->isgroupman . "

dal version:      " . $DALobj->dalversion . "
data format:      " . $DALobj->format . "
";

unless (-e $DALobj->cookiefile) {
	print "cookiefile does not exists!\n";
} else {
	open(DCF, $DALobj->cookiefile);
	while(<DCF>) { print $_; }
	close DCF;
}

print "cookie values taken from dalcookies:\n" . Dumper($DALobj->dalcookies) . "\n\n";

print "cookie file located at: " . $DALobj->cookiefile ."\n\n";

__END__