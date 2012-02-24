
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "a notes and bookmarks manager with tagging",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DBD::SQLite" => "1.08",
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "HTTP::Server::Simple" => "0.08",
    "HTTP::Server::Simple::CGI" => 0,
    "Test::HTTP::Server::Simple" => "0.02",
    "Test::More" => "0.96",
    "Test::WWW::Mechanize" => "1.04"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Rubric",
  "EXE_FILES" => [
    "bin/rubric"
  ],
  "LICENSE" => "perl",
  "NAME" => "Rubric",
  "PREREQ_PM" => {
    "App::Cmd" => 0,
    "App::Cmd::Command" => 0,
    "App::Cmd::Command::commands" => 0,
    "CGI::Application" => 3,
    "CGI::Carp" => 0,
    "CGI::Cookie" => 0,
    "Carp" => 0,
    "Class::Accessor" => 0,
    "Class::DBI" => "0.96",
    "Class::DBI::AbstractSearch" => 0,
    "Crypt::CBC" => 0,
    "DBI" => 0,
    "Date::Span" => "1.12",
    "DateTime" => 0,
    "Digest::MD5" => 0,
    "Email::Address" => 0,
    "Email::Send" => 0,
    "Encode" => 2,
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "HTML::CalendarMonth" => 0,
    "HTML::TagCloud" => 0,
    "HTML::Widget::Factory" => "0.03",
    "JSON" => 2,
    "LWP::Simple" => 0,
    "MIME::Base64" => 0,
    "Scalar::Util" => 0,
    "String::TagString" => 0,
    "String::Truncate" => 0,
    "Sub::Exporter" => 0,
    "Template" => "2.00",
    "Template::Filters" => 0,
    "Template::Plugin::Class" => "0.12",
    "Time::Piece" => 0,
    "YAML::XS" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.150",
  "test" => {
    "TESTS" => "t/*.t t/www/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


