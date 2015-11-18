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

# end session, logout
print "Logout message:\n" . $DALobj->DALlogout;
print "Username should be empty string now: '" . $DALobj->username . "'\n";