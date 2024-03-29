use strict;
use warnings;
package Rubric::WebApp::Login::HTTP;
# ABSTRACT: process web login from HTTP authentication
$Rubric::WebApp::Login::HTTP::VERSION = '0.155';
use parent qw(Rubric::WebApp::Login);

# =head1 DESCRIPTION
#
# This module checks for information needed to confirm that a user is logged into
# the Rubric.
#
# =head1 METHODS
#
# =head2 get_login_username
#
# This method returns the REMOTE_USER environment variable.
#
# =cut

sub get_login_username { $ENV{REMOTE_USER} }

# =head2 authenticate_login
#
# This method always returns true.  (The assumption, here, is that the HTTP
# server has already taken care of authentication.)
#
# =cut

sub authenticate_login { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::Login::HTTP - process web login from HTTP authentication

=head1 VERSION

version 0.155

=head1 DESCRIPTION

This module checks for information needed to confirm that a user is logged into
the Rubric.

=head1 METHODS

=head2 get_login_username

This method returns the REMOTE_USER environment variable.

=head2 authenticate_login

This method always returns true.  (The assumption, here, is that the HTTP
server has already taken care of authentication.)

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
