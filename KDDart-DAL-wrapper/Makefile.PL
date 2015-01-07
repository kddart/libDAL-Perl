use 5.016002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'KDDart::DAL::wrapper',
    VERSION_FROM      => 'lib/KDDart/DAL/wrapper.pm', # finds $VERSION
    PREREQ_PM         => {
                  'LWP::UserAgent'        => 6.04,
                  'HTTP::Request::Common' => 6.0,
                  'HTTP::Cookies'         => 6.01,
                  'Digest::HMAC_SHA1'     => 1.03,
                  'Class::Tiny'           => 1.0,
                  'XML::Simple'           => 2.18,
                  'Try::Tiny'             => 0.18,
                  'JSON'                  => 2.53,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/KDDart/DAL/wrapper.pm', # retrieve abstract from module
       AUTHOR         => 'Grzegorz Uszynski') : ()),
);
