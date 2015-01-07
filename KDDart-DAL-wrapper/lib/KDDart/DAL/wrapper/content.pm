package KDDart::DAL::wrapper::content;

use 5.016002;
use strict;
use warnings;

use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);

use Class::Tiny;

# my $content = $DALobj->DALgetContent( dalurl => 'list/site/20/page/1' );
sub DALgetContent {
	my $self       = shift;
	my %args       = @_;
	my $dalurl     = $args{ dalurl };
	$self->error(0);
	$self->errormsg("");
	
	my ($cookiefile, $browser) = $self->_makeBrowser() unless $self->browser;
	
	my $url_ed    = $self->baseurl . "switch/extradata/" . $self->extradata;
	my $ed_req    = POST($url_ed);
	my $ed_res    = $self->browser->request($ed_req);
	
	my $ed_content = $self->_checkResponse( response => $ed_res );
		
	if ($self->error) {
		print "switch extradata error: $ed_content\n" if $self->verbose;
		return $ed_content;
	}
	
	my $url       = $self->baseurl . $dalurl;
	$url          = $self->_formatURL( url => $url );
	my $get_req   = GET($url);
	my $get_res   = $self->browser->request($get_req);
	
	my $get_content = $self->_checkResponse( response => $get_res );
		
	if ($self->error) {
		print "get request error: $get_content\n" if $self->verbose;
	}
	
	return $get_content;
}

sub DALpostContent {
	my $self       = shift;
	my %args       = @_;
	my $dalurl     = $args{ dalurl };  # url to send to
	my $params     = $args{ params };  # list of parameters for the request
	$self->error(0);
	$self->errormsg("");
	
	if (defined $params) {
		if (ref $params ne 'HASH') {
			$self->error(1);
			$self->errormsg("Expected hash ref for params");
			return undef;
		}
	}
	
	my ($cookiefile, $browser) = $self->_makeBrowser() unless $self->browser;
	
	my $url_ed    = $self->baseurl . "switch/extradata/" . $self->extradata;
	my $ed_req    = POST($url_ed);
	my $ed_res    = $self->browser->request($ed_req);
	
	my $ed_content = $self->_checkResponse( response => $ed_res );
		
	if ($self->error) {
		print "switch extradata error: $ed_content\n" if $self->verbose;
		return $ed_content;
	}
	
	my $rand = $self->_makeRandomString( -len => 16 );
	
	my $url  = $self->baseurl . $dalurl;
	$url     = $self->_formatURL( url => $url );
	
	my $atomic_data   = q{};
	my $para_order    = q{};
	my $sending_param = [];
	
	foreach my $param (keys %{ $params }) {
		$atomic_data .= $params->{ $param };
		$para_order  .= $param . ',';
		push(@{$sending_param}, $param => "$params->{$param}");
	}
	
	my $data2sign = q{};
	$data2sign   .= "$url";
	$data2sign   .= "$rand";
	$data2sign   .= "$atomic_data";
	
	my $signature = hmac_sha1_hex($data2sign, $self->writetoken);
	
	push(@{$sending_param}, 'rand_num'       => "$rand");
	push(@{$sending_param}, 'url'            => "$url");
	push(@{$sending_param}, 'signature'      => "$signature");
	push(@{$sending_param}, 'param_order'    => "$para_order");
	
	my $post_req = POST($url, $sending_param);
	my $post_res = $self->browser->request($post_req);
	
	my $res_content = $self->_checkResponse( response => $post_res );
		
	if ($self->error) {
		print "post request error: $ed_content\n" if $self->verbose;
	}
	
	return $res_content;
}

1;

__END__

=pod

=head1 NAME

KDDart::DAL::wrapper::content - sub module of KDDart::DAL::wrapper

=head1 DESCRIPTION

Retrieve content of KDDart using DAL

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
