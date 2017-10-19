package KDDart::DAL::wrapper::content;

use 5.016002;
use strict;
use warnings;

use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use Digest::MD5 qw(md5 md5_hex md5_base64);
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
	
	if ($self->groupid >= 0) {
		my $switch_content = $self->SwitchExtraData();
		
		if ($self->error) {
			$self->errormsg() .= " - could not switch extra data";
			print "switch extradata error: $switch_content\n" if $self->verbose;
			return $switch_content;
		}
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
	$self->error(0);
	$self->errormsg("");
	
	my %args       = @_;
	my $dalurl     = $args{ dalurl };       # url to send request to
	my $params     = $args{ params };       # list of parameters for the request
	
	my $nosign     = 0;                     # do not calculate signature (so no write operations will be performed)
	if ($args{ nosign }) { $nosign = 1; }
	
	if (defined $params) {
		if (ref $params ne 'HASH') {
			$self->error(1);
			$self->errormsg("Expected hash ref for parameters");
			return;
		}
	}
	
	if ($self->groupid >= 0) {
		my $switch_content = $self->SwitchExtraData();
		
		if ($self->error) {
			$self->errormsg() .= " - could not switch extra data";
			print "switch extradata error: $switch_content\n" if $self->verbose;
			return $switch_content;
		}
	}
	
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
	
	my %upcontentformvalues = ( 'm' => 1, 'M' => 1, 'f' => 1, 'F' => 1 ); # handling lc and uc
	my ($upcontentform, $upload, $uploadfilename, $uploadmd5);
	
	# file upload if requested
	if ($args{ upcontentform }) {
		unless (exists $upcontentformvalues{ $args{ upcontentform } }) {
			$self->error(1);
			$self->errormsg("Error: value for upcontentform parameter can only be f or m");
			return;
		}
		
		if ($nosign) {
			$self->error(1);
			$self->errormsg("Error: can not request file upload and no signature at the same time");
			return;
		}
		
		$upcontentform = lc( $args{ upcontentform } );
		
		if ($upcontentform eq 'm') {
			unless ( $args{ upload } ) {
				$self->error(1);
				$self->errormsg("Error: No content for upload provided");
				return;
			}
			
			$upload = $args{ upload };
			$uploadmd5 = md5_hex($upload);
			push(@{$sending_param}, 'uploadfile' => [undef, 'uploadfile', 'Content' => $upload]);
			
		} elsif ($upcontentform eq 'f') {
			unless ( $args{ uploadfilename } ) {
				$self->error(1);
				$self->errormsg("Error: No file name for upload provided");
				return;
			}
			
			$uploadfilename = $args{ uploadfilename };
			
			my $uploadfh;
			
			unless ( open ($uploadfh, '<', $uploadfilename) ) {
				$self->error(1);
				$self->errormsg("Error: File for upload provided can not be accessed");
				return;
			}
			
			my $md5_engine = Digest::MD5->new();
			$md5_engine->addfile($uploadfh);
			$uploadmd5 = $md5_engine->hexdigest();
			close $uploadfh;
			push(@{$sending_param}, 'uploadfile' => [$uploadfilename]);
		}
	}
	
	# only when calcualating signature required
	unless ($nosign) {
		my $rand = $self->_makeRandomString( -len => 16 );
		
		my $data2sign = q{};
		$data2sign   .= "$url";
		$data2sign   .= "$rand";
		$data2sign   .= "$atomic_data";
		
		if ($uploadmd5) {
			$data2sign   .= "$uploadmd5";
		}
		
		my $signature = hmac_sha1_hex($data2sign, $self->writetoken);
		
		push(@{$sending_param}, 'rand_num'       => "$rand");
		push(@{$sending_param}, 'url'            => "$url");
		push(@{$sending_param}, 'signature'      => "$signature");
		push(@{$sending_param}, 'param_order'    => "$para_order");
	}
	
	my %postparams = ('Content' => $sending_param);
	
	if ($upcontentform) {
		$postparams{ Content_Type } = 'multipart/form-data';
	}
	
	my $post_req = POST($url, %postparams);
	my $post_res = $self->browser->request($post_req);
	
	my $res_content = $self->_checkResponse( response => $post_res );
		
	if ($self->error) {
		print "post request error: $res_content\n" if $self->verbose;
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
