package Rubric::CLI::Command;

=head1 NAME

Rubric::CLI::Command - a base class for rubric commands

=head1 VERSION

 $Id: /my/cs/projects/rubric/trunk/lib/Rubric/CLI/Command.pm 18100 2006-01-26T13:59:16.285684Z rjbs  $

=cut

use strict;
use warnings;

use Carp ();
use Getopt::Long::Descriptive ();

=head1 METHODS

=head2 C< execute >

This method does whatever it is the command should do!

=cut

sub execute {
  my ($class) = @_;
  Carp::croak "$class does not implement mandatory method 'execute'\n";
}

1;
