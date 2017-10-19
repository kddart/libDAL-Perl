package KDDart::DAL::wrapper::users;

use 5.016002;
use strict;
use warnings;

use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use HTTP::Request::Common qw(POST GET);

use Class::Tiny;

# DALlogin( username => $username, password => $password, passwordcleartext => [0|1] );
sub DALlogin {
	my $self              = shift;
	$self->error(0);
	$self->errormsg("");
	my %args              = @_;
	
	my $username          = $args{username};
	my $password          = $args{password};
	my $passwordcleartext = 0;
	if ($args{passwordcleartext}) { $passwordcleartext = 1; }
	
	if ($self->error) { # problem while creating browser
		print $self->errormsg . "\n" if $self->verbose;
		return;
	}
	
	my $url            = $self->baseurl . "login/$username/" . $self->loginexpire;
	my $rand           = $self->_makeRandomString( -len => 16 );
	my $signature      = $password;
	
	if ($passwordcleartext) {
		my $hash_pass      = hmac_sha1_hex($username, $password);
		my $session_pass   = hmac_sha1_hex($rand, $hash_pass);
		$signature         = hmac_sha1_hex($url, $session_pass);
		#print $url . "\n" . $hash_pass . "\n" . $rand . "\n" . $session_pass . "\n" . $signature . "\n" if $self->verbose;
	}
	
	my $auth_req_res   = POST($url, [ rand_num => "$rand", url => "$url", signature => "$signature", ]);
	my $auth_response  = $self->browser->request($auth_req_res);
	
	print "Login url: " . $url . "\n" if $self->verbose;
	
	my $content = $self->_checkResponse( response => $auth_response );
		
	if ($self->error) {
		return $content;
	}
	
	my $content_ref = $self->content2data(datasource => $content);
	my $write_token = $content_ref->{'WriteToken'}->[0]->{'Value'};
	my $userid      = $content_ref->{'User'}->[0]->{'UserId'};
	
	chomp($write_token);
	
	$self->writetoken($write_token);
	$self->username($username);
	$self->userid($userid);
	$self->islogin(1);
	
	my $cookie_jar = $self->browser->cookie_jar;
	
	$cookie_jar->save;
	
	print $cookie_jar->as_string( 1 ) if $self->verbose;
	
	$cookie_jar->scan(sub {
		$self->dalcookies->{$_[1]} = { value => $_[2], path => $_[3], domain => $_[4], expires => $_[8] };
	});
	
	if ($self->autogroupswitch) {
		my $gurl = $self->baseurl . 'list/group';
		my $groups_req = GET( $gurl );
		my $groups_response = $self->browser->request($groups_req);
		my $groups = $self->_checkResponse( response => $groups_response );
		
		if ($self->error) {
			return $groups;
		}
		
		my $groups_ref = $self->content2data(datasource => $groups);
		
		my $groupid = $groups_ref->{SystemGroup}->[0]->{SystemGroupId};
		
		my $gcontent = $self->SwitchGroup( groupid => $groupid );
		if ($self->error) {
			return $gcontent;
		}
		
		print "Autoswitch to group id: $groupid\n" if $self->verbose;
		#print "[groups data]:\n" . $groups . "\n\n";
	}
	
	return $content;
}

sub SwitchGroup {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	my %args = @_;
	
	unless (defined $args{groupid}) {
		$self->error(1);
		$self->errormsg("Group id needed - not provided");
		return;
	}
	
	my $url = $self->baseurl . "switch/group/$args{groupid}";
	
 	my $switch_group_req = GET($url);
	
	my $switch_group_response = $self->browser->request($switch_group_req);
	my $content = $self->_checkResponse( response => $switch_group_response );
	
	if ($self->error) {
		return $content;
	}
	
	my $content_ref = $self->content2data(datasource => $content);
	if ($self->error) {
		return $content;
	}
	
	my %TF = (FALSE => 0, TRUE => 1);
	
	$self->groupid($args{groupid});
	$self->groupname( $content_ref->{Info}->[0]->{GroupName} );
	$self->isgroupman( $TF{ $content_ref->{Info}->[0]->{GAdmin} } );
	
	return $content;
}

sub SwitchExtraData {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	
	my $url = $self->baseurl . "switch/extradata/" . $self->extradata;
	
	my $switch_extradata_req = POST($url);
	
	my $switch_extradata_response = $self->browser->request($switch_extradata_req);
	my $content = $self->_checkResponse( response => $switch_extradata_response );
	
	if ($self->error) {
		return $content;
	}
	
	my $content_ref = $self->content2data(datasource => $content);
	if ($self->error) {
		return $content;
	}
	
	return $content;
}

sub DALlogout {
	my $self = shift;
	$self->error(0);
	$self->errormsg("");
	
	my $url = $self->baseurl . "logout";
	$url    = $self->_formatURL( url => $url );
	
	my $auth_req_res   = POST($url);
	my $auth_response  = $self->browser->request($auth_req_res);
	
	my $content = $self->_checkResponse( response => $auth_response );
	
	if ($self->error) {
		return $content;
	}
	
	unlink $self->cookiefile;
	$self->cookiefile('');
	$self->browser('');
	$self->writetoken('');
	$self->username('');
	$self->userid(-1);
	$self->islogin(0);
	$self->groupid(-1);
	$self->groupname( '' );
	$self->isgroupman( 0 );
	$self->dalcookies( {} );
	
	return $content;
}

1;

__END__

=pod

=head1 NAME

KDDart::DAL::wrapper::users - sub module of KDDart::DAL::wrapper

=head1 DESCRIPTION

User related methods in DAL

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
