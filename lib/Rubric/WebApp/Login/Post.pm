use strict;
use warnings;
package Rubric::WebApp::Login::Post;
{
  $Rubric::WebApp::Login::Post::VERSION = '0.152';
}
use base qw(Rubric::WebApp::Login);
# ABSTRACT: process web login from query parameters

use Digest::MD5 qw(md5_hex);


sub get_login_username {
	my ($class, $webapp) = @_;

	$webapp->session->param('current_user') || $webapp->query->param('user');
}


sub authenticate_login {
	my ($self, $webapp, $user) = @_;

	return 1 if
		$webapp->session->param('current_user') and
		$webapp->session->param('current_user') eq $user;

	my $password = $webapp->query->param('password');

	return (md5_hex($password) eq $user->password);
}


sub set_current_user {
	my ($self, $webapp, $user) = @_;

	$webapp->session->param(current_user => $user->username);
	$self->SUPER::set_current_user($webapp, $user);
}

1;

__END__
=pod

=head1 NAME

Rubric::WebApp::Login::Post - process web login from query parameters

=head1 VERSION

version 0.152

=head1 DESCRIPTION

This module checks the submitted query for information needed to confirm that a
user is logged into the Rubric.

=head1 METHODS

=head2 get_login_username

This checks for the username in a current login request.  First it checks
whether there is a C<current_user> value in this session.  If not, it looks for
a C<user> query parameter.

=head2 authenticate_login($webapp, $user)

This returns true if the username came from the session.  Otherwise, it checks
for a C<password> query parameter and compares its md5sum against the user's
stored password md5sum.

=head2 set_current_user($webapp, $user)

This method sets the current user in the session and then calls the superclass
C<set_current_user>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

