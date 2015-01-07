package KDDart::DAL::wrapper::utils;

use 5.016002;
use strict;
use warnings;

use XML::Simple;

use JSON;
use Try::Tiny;
my $j = JSON->new;

use Class::Tiny;

sub content2data {
	my $self     = shift;
	$self->error(0);
	$self->errormsg("");
	my %args     = @_;
	
	my $data_src = $args{ datasource };
	my $tag_name = $args{ tagname };
	
	my $data_ref = {};
	
	if ($self->format eq 'json') {
		$data_ref = $self->json2data( datasource => $data_src, tagname => $tag_name );
	} else {
		$data_ref = $self->xml2data( datasource => $data_src, tagname => $tag_name );
	}
	
	if ($self->error) {
		return undef;
	}
	
	return $data_ref;
}

sub xml2data {
	my $self     = shift;
	$self->error(0);
	$self->errormsg("");
	my %args     = @_;
	
	my $data_src = $args{ datasource };
	my $tag_name = $args{ tagname };
	
	unless ($data_src) {
		$self->error(1);
		$self->errormsg("XML data string or file not provided");
		return undef;
	}

	my $data_ref = eval { XMLin($data_src, ForceArray => 1) };
	if ($@) {
		$self->error(1);
		$self->errormsg("XML data format corrupted: " . $@ );
		return undef;
	}

	if ($tag_name) {
		if ($data_ref->{ $tag_name }) {
			return $data_ref->{ $tag_name };
		} else {
			$self->error(1);
			$self->errormsg("tag $tag_name not present in the provided data structure");
			return undef;
		}
	} else {
		return $data_ref;
	}
}

sub json2data {
	my $self     = shift;
	$self->error(0);
	$self->errormsg("");
	my %args     = @_;
	
	my $data_src = $args{ datasource };
	my $tag_name = $args{ tagname };
	
	my $data_ref;
	try {
		$data_ref = $j->decode($data_src);
	} catch {
		$self->error(1);
		$self->errormsg("Not a valid json string provided");
		return undef;
	};
	
	if ($tag_name) {
		if ($data_ref->{ $tag_name }) {
			return $data_ref->{ $tag_name };
		} else {
			$self->error(1);
			$self->errormsg("tag $tag_name not present in the provided data structure");
			return undef;
		}
	}
	
	return $data_ref;
}

1;

__END__

=pod

=head1 NAME

KDDart::DAL::wrapper::utils - sub module of KDDart::DAL::wrapper

=head1 DESCRIPTION

Various utility methods for DAL wrapper

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
