#!/usr/bin/perl -w

# =========================================================== #
# Grzegorz Uszynski (2014-12-22)
# version 1.0
# basic example how to use KDDart::DAL::wrapper library
# =========================================================== #

use strict;
use KDDart::DAL::wrapper;
use Data::Dumper;

unless (scalar @ARGV == 4) {
	print "\n  Usage: perl -w $0 <dal_url> <username> <password> <groupid>\n\n";
	exit 0;
}

# SETUP your run
my $dalbase = $ARGV[0];
my $user    = $ARGV[1];
my $pass    = $ARGV[2];
my $group   = $ARGV[3];

# build an object (only baseurl is required)
my $DALobj = KDDart::DAL::wrapper->new( baseurl => $dalbase, verbose => 0, autogroupswitch => 1, extradata => 0 );
&onError("problem with object creation") if $DALobj->error;

my $randomstr = $DALobj->_makeRandomString( -len => 12 );

print "

# starting the run #
current base url: " . $DALobj->baseurl . "
random string:    " . $randomstr . "
";

# login into DAL
my $result = $DALobj->DALlogin( username => $user, password => $pass, passwordcleartext => 1 );
&onError($result) if $DALobj->error;

print "
# user login #
write token:      " . $DALobj->writetoken . "
username:         " . $DALobj->username . "
userid:           " . $DALobj->userid . "
cookie file at:   " . $DALobj->cookiefile . "

# group auto switch to first available group #
groupname:        " . $DALobj->groupname . "
groupid:          " . $DALobj->groupid . "
group manager:    " . $DALobj->isgroupman . "

dal version:      " . $DALobj->dalversion . "
data format:      " . $DALobj->format . "
";

unless (-e $DALobj->cookiefile) {
	print "cookiefile does not exists!\n";
}

my $groups = $DALobj->DALgetContent( dalurl => 'list/group' );
&onError($groups) if $DALobj->error;
print "\nList of groups for a user:\n" . $groups . "\n";

my $swgr = $DALobj->SwitchGroup(groupid => $group);
&onError($swgr) if $DALobj->error;

print "
# group after switch #
groupname:        " . $DALobj->groupname . "
groupid:          " . $DALobj->groupid . "
group manager:    " . $DALobj->isgroupman . "
";

# some operations

# get version
my $version = $DALobj->DALgetContent( dalurl => 'get/version' );
&onError($version) if $DALobj->error;

# convert json to perl hash
my $versionhash = $DALobj->json2data( datasource => $version);
&onError($versionhash) if $DALobj->error;

# extract version number
my $versionNum = $versionhash->{Info}->[0]->{Version};
print "Version number extracted from json: " . $versionNum . "\n\n";

# list first page with max 2 organisations, only OrganisationId field, only OrganisationId > 0
# using POST request
my $organisations = $DALobj->DALpostContent(
	dalurl => 'list/organisation/2/page/1',
	params => {
		FieldList => 'OrganisationId',
		Filtering => 'OrganisationId > 0'
	}
);
&onError($organisations) if $DALobj->error;

print "Current 2 organisations on the page 1:\n" . $organisations . "\n\n";

# end session, logout
print "Logout message:\n" . $DALobj->DALlogout;
print "Username should be empty string now: '" . $DALobj->username . "'\n";

# =============================================================
sub onError {
	print "ERROR: " . $DALobj->errormsg . "\n";
	print "DAL response: \n" . $_[0] . "\n\n";
	exit 1;
}

__END__