package Rubric::WebApp::Login;
use strict;
use warnings;

=head1 NAME

Rubric::WebApp::Login - web login processing

=head1 VERSION

version 0.01

 $Id: Login.pm,v 1.1 2004/12/20 13:24:04 rjbs Exp $

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module checks for information needed to confirm that a user is logged into
the Rubric.

=head1 METHODS

=head2 Rubric::WebApp::Login->check_for_login($webapp)

This method is called by the WebApp's C<cgiapp_init>, and checks for a login
attempt in the submitted request.  First, it checks for an HTTP login with
C<check_for_http_login>, then for a login via POSTed parameters with
C<check_for_post_login>.

=cut

sub check_for_login {
	my ($self, $webapp) = @_;
	
	return unless my $username = $self->get_login_username($webapp);

	$username = $self->map_username($username);
	return unless $self->valid_username($username);
	return unless my $user = $self->get_login_user($username);
	return unless $self->authenticate_login($webapp, $user);
	$webapp->param('user_pending', 1) if $user->verification_code;

	$self->set_current_user($webapp, $user);
}

=head2 get_login_username($webapp)

This method returns the login username taken from the request.  It is not
necessarily the name of a Rubric user (see C<map_username>).

This must be implemented by the login subclass.

=cut

sub get_login_username { die "get_login_username unimplemented" }

=head2 map_username($username)

This method returns the Rubric username to which the login name maps.  By
default, it returns the C<$username> verbatim.

=cut

sub map_username { $_[1] }

=head2 valid_username($username)

Returns a true or false value, depending on whether the given username string
is a valid username.

=cut

sub valid_username {
	my ($self, $username) = @_;
	$username =~ /^\w+$/;
}

=head2 get_login_user($username)

Given a username, this method returns the Rubric::User object for the user.

=cut

sub get_login_user {
	my ($self, $username) = @_;
	Rubric::User->retrieve($username);
}

=head2 authenticate_login($webapp, $user)

This method attempts to authenticate the user's login, checking the given
password or performing any other needed check.  It returns true or false.

This must be implemented by the login subclass.

=cut

sub authenticate_login { die "authenticate_login unimplemented" }

=head2 set_current_user($webapp, $user)

This method sets the current user on the WebApp by setting the WebApp's
"current_user" attribute to the Rubric::User object.

=cut

sub set_current_user {
	my ($self, $webapp, $user) = @_;

	$webapp->param(current_user => $user);
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
