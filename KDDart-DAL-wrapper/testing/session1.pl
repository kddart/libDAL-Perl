#!/usr/bin/perl -w

# =========================================================== #
# Grzegorz Uszynski (2015-06-12)
# version 1.0
# KDDart session using KDDart::DAL::wrapper library
# =========================================================== #

use strict;
use KDDart::DAL::wrapper;
use Data::Dumper;

use Utils;

my $CONFIG = readConfig();

# SETUP your run
my $dalbase      = $CONFIG->{baseurl};
my $cookiefile   = $CONFIG->{cookiefile};

# build an object (only baseurl is required)
my $DALobj = KDDart::DAL::wrapper->new( baseurl => $dalbase, verbose => 0, autogroupswitch => 1, extradata => 0, cookiefile => $cookiefile );
&onError("problem with object creation", $DALobj->errormsg) if $DALobj->error;

print "
# user login #
write token:      " . $DALobj->writetoken . "
username:         " . $DALobj->username . "
userid:           " . $DALobj->userid . "
cookie file at:   " . $DALobj->cookiefile . "
is user loggedin: " . $DALobj->islogin . "

# group auto switch to first available group #
groupname:        " . $DALobj->groupname . "
groupid:          " . $DALobj->groupid . "
group manager:    " . $DALobj->isgroupman . "

dal version:      " . $DALobj->dalversion . "
data format:      " . $DALobj->format . "
";


__END__