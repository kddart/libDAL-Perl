package KDDart::DAL::wrapper::helper;

use 5.016002;
use strict;
use warnings;

use Class::Tiny qw( cookiefile browser );

use LWP::UserAgent;
use HTTP::Cookies;
use File::Temp qw/ tempfile tempdir /;

sub _makeBrowser {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	my %args = @_;
	
	unless ($self->cookiefile) { # not set, create in tmp
		my $tmpdir = tempdir( 'DALcookie.XXXXXXXXXXXXXX', CLEANUP => 0, TMPDIR => 1 );
		my ($fh, $fname) = tempfile( UNLINK => 1, DIR => $tmpdir );
		close $fh;
		$self->cookiefile( $fname . ".dat" );
	}
	
	my $browser    = LWP::UserAgent->new();
	my $cookie_jar = HTTP::Cookies->new( file => $self->cookiefile, autosave => 1, );
	
	my %headers = ( json => 'application/json', xml => 'text/sml' );
	$browser->default_header('Accept' => $headers{ $self->format } );
	
	$browser->cookie_jar($cookie_jar);
	$cookie_jar->save; # force saving
	
	$self->browser( $browser );
	
	return ($self->cookiefile, $self->browser);
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
			my $connector = '?';
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
		return undef;
	}
	
	if ($args{response}->code == 200) {
		return $args{response}->content;
	} elsif ($args{response}->code == 401) {
		$self->error(1);
		$self->errormsg("DAL credential related error; code 401");
		return $args{response}->content;
	} elsif ($args{response}->code == 420) {
		$self->error(1);
		$self->errormsg("DAL error - see error message and code; code 420");
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
