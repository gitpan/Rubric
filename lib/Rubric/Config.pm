package Rubric::Config;

=head1 NAME

Rubric::Config - the configuration data for a Rubric

=head1 VERSION

 $Id: Config.pm,v 1.10 2004/12/20 13:24:04 rjbs Exp $

=head1 DESCRIPTION

Rubric::Config provides access to the configuration data for a Rubric.  The
basic implementation stores its configuration in YAML in a text file found
using Config::Auto's find_file function.

=cut

use strict;
use warnings;

use base qw(Class::Accessor);
use Config::Auto;
use YAML;

my $config_filename = 'rubric.yml';

sub import {
	my ($class) = shift;
	$config_filename = shift if @_;
}

=head1 METHODS

=head2 read_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

my $config;
sub read_config {
	return $config if $config;

	my $config_file = Config::Auto::find_file($config_filename);
	$config = YAML::LoadFile($config_file);
}

sub make_ro_accessor {
	my ($class, $field) = @_;
	sub { $class->read_config->{$field} }
}

__PACKAGE__->mk_ro_accessors(qw(
	css_href
	dsn
	email_from
	login_class
	private_system
	registration_closed
	skip_newuser_verification
	smtp_server
	template_path
	uri_root
));

=head2 dsn

This method returns the DSN to be used by Rubric::DBI to connect to the
Rubric's database.

=head2 login_class

This is the class used to check for logins; it should subclass
Rubric::WebApp::Login.  If not supplied, the default is
Rubric::WebApp::Login::Post.

=head2 uri_root

This method returns the URI for the root of the Rubric::WebApp install.

=head2 css_href

This method returns the URI for the stylesheet to be used by Rubric::WebApp
pages.

=head2 skip_newuser_verification

If true, users will be created without verification codes, and won't get
verification emails.

=head2 template_path

This method returns the INCLUDE_PATH passed to Template when creating the
template renderer.

=head2 email_from

This method returns the email address from which Rubric will send email.

=head2 smtp_server

This method returns the SMTP server used to send email.

=head2 registration_closed

This method returns a true value if registration isn't open to the world.

=head2 private_system

This method returns a true value if the Rubric is private.  A private Rubric
restricts unauthenticated sessions to logging in or registering an account (and
if registration is closed, they can only log in).

=head1 TODO

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
