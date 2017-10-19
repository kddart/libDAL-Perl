package KDDart::DAL::wrapper::helper;

use 5.016002;
use strict;
use warnings;

use Carp qw( croak );

use Class::Tiny qw( cookiefile cookiefolder browser ), {
	writetoken           => '',         # will store write token after login
	username             => '',         # who is logged in
	userid               => -1,         # user numeric id
	groupname            => '',         # current group name
	groupid              => -1,         # current group id
	isgroupman           => 0,          # flag if current user is group manager/owner
	groupselectionstatus => 0,
	dalversion           => 0,          # dal version
	islogin              => 0,          # login status
};

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common qw(POST GET);
use File::Temp qw/ tempfile tempdir /;
use JSON;
use Try::Tiny;
my $j = JSON->new;

sub BUILD {
	my ($self, $args) = @_;
	
	unless ($self->cookiefolder) {
		$self->cookiefolder ( tempdir( 'DALcookie.XXXXXXXXXXXXXX', CLEANUP => 0, TMPDIR => 1 ) );
	}
	
	unless ($self->cookiefile) { # not set, create in tmp
		my ($fh, $fname) = tempfile( UNLINK => 0, DIR => $self->cookiefolder, SUFFIX => '.dat' );
		close $fh;
		$self->cookiefile( $fname );
		unlink $fname; # so HTTP::Cookies does not complain
	}
	
	my $browser    = LWP::UserAgent->new();
	my $cookie_jar = HTTP::Cookies->new( file => $self->cookiefile, autosave => 0, );
	
	my %headers = ( json => 'application/json', xml => 'text/xml' );
	$browser->default_header('Accept' => $headers{ $self->format } );
	
	$browser->cookie_jar($cookie_jar);
	#$cookie_jar->save; # force saving
	
	$self->browser( $browser );
	
	$cookie_jar->scan(sub {
		$self->dalcookies->{$_[1]} = { value => $_[2], path => $_[3], domain => $_[4], expires => $_[8] };
	});
	
	my $url       = $self->baseurl . 'get/login/status?ctype=json';
	my $get_req   = GET($url);
	my $get_res   = $self->browser->request($get_req);
	
	my $url2      = $self->baseurl . 'get/version?ctype=json';
	my $get_req2  = GET($url2);
	my $get_res2  = $self->browser->request($get_req2);
	
	if ( ($get_res->code != 200 ) || ($get_res2->code != 200)) {
		$self->error(1);
		$self->errormsg("Can not contact the server to get status information");
		croak $self->errormsg;
	} else {
		my $get_content = $get_res->content;
		print $get_content . "\n" if $self->verbose;
		
		my $get_content2 = $get_res2->content;
		print $get_content2 . "\n" if $self->verbose;
		
		my $content_ref;
		my $content_ref2;
		try {
			$content_ref  = $j->decode($get_content);
			$content_ref2 = $j->decode($get_content2);
		} catch {
			$self->error(1);
			$self->errormsg("Not a valid json string provided while getting status information");
			croak $self->errormsg;
		};
		
		### DAL to provide userid, username, groupid, groupname, writetoken, groupadminstatus
		
		$self->islogin( $content_ref->{Info}->[0]->{LoginStatus} );
		$self->writetoken( $content_ref->{Info}->[0]->{WriteToken} );
		$self->groupid( $content_ref->{Info}->[0]->{GroupId} );
		$self->userid( $content_ref->{Info}->[0]->{UserId} );
		$self->groupselectionstatus($content_ref->{Info}->[0]->{GroupSelectionStatus});
		$self->username( $content_ref->{Info}->[0]->{UserName} );
		$self->groupname( $content_ref->{Info}->[0]->{GroupName} );
		
		$self->dalversion( $content_ref2->{Info}->[0]->{Version} );
		
	}
}

# my $random_num = $DALobj->_makeRandomString( -len => 32 );
sub _makeRandomString {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	
	my $len = 32;
	my %args = @_;
	if ($args{-len}) { $len = $args{-len}; }
	my @chars2use = (0 .. 9);
	my $randstring = join("", map $chars2use[rand @chars2use], 0 .. $len);
	return $randstring;
}

sub _formatURL {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	my %args = @_;
	
	if ($args{url}) {
		if ($self->format eq 'json') {
			my $connector = "?";
			if ($args{url} =~ /\?/) { $connector = '&'; }
			$args{url} .= $connector . 'ctype=json';
		}
		return $args{url};
	}
}

sub _checkResponse {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	my %args = @_;
	
	unless ( $args{response} ) {
		$self->error(1);
		$self->errormsg("Required argument 'response' not provided");
		return;
	}
	
	if ($args{response}->code == 200) {
		return $args{response}->content;
	} elsif ($args{response}->code == 401) {
		my $content = $self->content2data(datasource => $args{response}->content, tagname => 'Error');
		$self->error(1);
		$self->errormsg("DAL credential related error; code 401; DAL said [".$content->[0]->{Message}."]");
		return $args{response}->content;
	} elsif ($args{response}->code == 420) {
		my $content = $self->content2data(datasource => $args{response}->content, tagname => 'Error');
		$self->error(1);
		$self->errormsg("DAL error; code 420; DAL said [".$content->[0]->{Message}."]");
		return $args{response}->content;
	} else {
		$self->error(1);
		$self->errormsg("HTTP error - " . $args{response}->code);
		return $args{response}->status_line;
	}
}

1;

__END__

=pod

=head1 NAME

KDDart::DAL::wrapper::helper - sub module of KDDart::DAL::wrapper

=head1 DESCRIPTION

Helper methods for the package - mostly used internally

=head1 AUTHOR

Grzegorz Uszynski, Diversity Arrays Technology Pty Ltd


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Diversity Arrays Technology Pty Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
