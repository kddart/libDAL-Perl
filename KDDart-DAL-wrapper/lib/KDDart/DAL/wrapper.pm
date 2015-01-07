package KDDart::DAL::wrapper;

use 5.016002;
use strict;
use warnings;
use Carp qw( croak );

use parent qw( KDDart::DAL::wrapper::helper KDDart::DAL::wrapper::users KDDart::DAL::wrapper::utils KDDart::DAL::wrapper::content );

use Class::Tiny qw( baseurl ), {
	error           => 0,          # internal - do not reset
	errormsg        => "",         # internal - do not reset
	verbose         => 0,          # never set to 1 in production (e.g. Dancer has a problem if something is written to STDOUT)
	format          => 'json',     # or xml
	extradata       => 0,          # set to 1 if want to get extra data in the output
	autogroupswitch => 0,          # auto group switch to first available group
};

use vars qw($VERSION);
$VERSION = '0.2.0';

sub BUILD {
	my ($self, $args) = @_;
	
	croak "baseurl has to be defined!" unless defined $self->baseurl;
	
	unless ($self->baseurl =~ /\/$/) {
		$self->baseurl($self->baseurl . '/');
	}
	
}

1;

__END__

=head1 NAME

KDDart::DAL::wrapper - Perl wrapper for KDDart DAL RESTful API

=head1 SYNOPSIS

  use KDDart::DAL::wrapper;
  my $DALobj = KDDart::DAL::wrapper->new( baseurl => 'http://dalserver.example.com/dal', %options );
  # with error checking
  if ($DALobj->error) {
    print $DALobj->errormsg . "\n";
    # maybe exit or something?
  }

=head1 DESCRIPTION

This is a wrapper module allowing to easily log to DAL and perform operations in the service.

=head1 EXPORT

None by default.

=head1 DAL METHODS


=head2 new

  my $DALobj = KDDart::DAL::wrapper->new( baseurl => 'http://dalserver.example.com/dal', %options );

Creates a DAL object to maintain the session. The options are:

baseurl         - Base DAL url, this is the only compulsory option to provide to the object

format          - Data format DAL will return after any request. By default 'json', but can be 'xml' too

extradata       - Flag [0|1], should the request return more data. By default '0'

verbose         - Flag [0|1], print messages to STDOUT, not desirable in many cases like web applications. By default '0'

cookiefile      - File name where the cookie is stored for HTTP::Cookies. Will be created if does not exists. If you already had a session and saved cookie file, you may provide it to the object for use

loginexpire     - 'no' by default, set to 'yes' if needed

autogroupswitch - Flag [0|1], should user after login get first available group from groups it belongs to. By default '0'


=head3 Set (reset) options

  $DALobj->format('xml'); # to change output format to xml


=head3 Get current object value

  my $current_format = $DALobj->format;  # what is the current format


=head2 DALlogin

  my ($content, $writetoken) = $DALobj->DALlogin( username => $username, password => $password, passwordcleartext => [0|1] );

Use this method to login to DAL. If you were successfully logged in, you need to follow with a SwitchGroup call to make most operations within DAL.


=head2 SwitchGroup

  $DALobj->SwitchGroup(groupid => $groupid);

Subscribe user to the group, so now all DAL call become available. User will act as a member of this group obtaining privileges to data assigned to the group of choice and possibly administrative privileges if within selected group the user is it's manager


=head2 DALlogout

  $DALobj->DALlogout();

Attempt to logout user from the system and destroy DAL session (locally will delete cookie file)


=head2 DALgetContent

  my $content = $DALobj->DALgetContent( dalurl => 'list/site/20/page/1' );

Making a simple GET request to DAL. Format your url (with parameters if needed) and provide to this call


=head2 DALpostContent

  my $content = $DALobj->DALpostContent( dalurl => 'list/organisation/20/page/1',
    params => {
      FieldList => 'OrganisationId',
      Filtering => 'OrganisationId > 0'
    }
  );

Making a POST request to DAL. Provide your url and hashref with parameters - if needed.


=head1 HELPER METHODS


=head2 xml2data

  my $hash_ref = $self->xml2data( datasource => $content, tagname => 'WriteToken' );

Converts xml response into Perl data structures


=head2 json2data

  my $hash_ref = $self->json2data( datasource => $content, tagname => 'WriteToken' );

Converts json response into Perl data structures


=head2 content2data

  my $hash_ref = $self->content2data( datasource => $content, tagname => 'WriteToken' );

Converts DAL response into Perl data structures using current setting for the format. Internally will use either xml2data or json2data.


=head1 Session Information

  $DALobj->writetoken;    # stores write token after login, empty string otherwise
  $DALobj->username;      # username who is logged in, empty string otherwise
  $DALobj->userid;        # user numeric id, undef otherwise
  $DALobj->groupname;     # current group name after switch group, empty string otherwise
  $DALobj->groupid;       # current group id, undef otherwise
  $DALobj->isgroupman;    # flag if current user is group manager/owner, only relevant after switch group
  $DALobj->dalversion;    # dal version, 0 if not yet set
  $DALobj->islogin;       # flag if user is logged in

=head1 SEE ALSO

DAL API documentation (http://www.kddart.org)


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
