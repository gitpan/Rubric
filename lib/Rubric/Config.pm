package Rubric::Config;

=head1 NAME

Rubric::Config - the configuration data for a Rubric

=head1 VERSION

 $Id: Config.pm,v 1.14 2005/01/03 13:15:59 rjbs Exp $

=head1 DESCRIPTION

Rubric::Config provides access to the configuration data for a Rubric.  The
basic implementation stores its configuration in YAML in a text file found
using Config::Auto's C<find_file> function.  By default, Rubric::Config looks
for C<rubric.yml>, but an alternate filename may be passed when using the
module:

 use Rubric:Config ".rubric_yml";

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

=head1 SETTINGS

These configuration settings can all be retrieved by methods of the same name.

=over 4

=item * dsn

the DSN to be used by Rubric::DBI to connect to the Rubric's database

=item * uri_root

the absolute URI for the root of the Rubric::WebApp install

=item * css_href

the absolute URI for the stylesheet to be used by Rubric::WebApp pages

=item * template_path

the INCLUDE_PATH passed to Template when creating the template renderers

=item * email_from

the email address from which Rubric will send email

=item * smtp_server

the SMTP server used to send email

=item * entries_query_class

This is the class used to process the C<entries> run method.  It defaults to
C<Rubric::WebApp::EntriesQuery>.

=item * login_class

This is the class used to check for logins; it should subclass
Rubric::WebApp::Login.  If not supplied, the default is
Rubric::WebApp::Login::Post.

=item * skip_newuser_verification

If true, users will be created without verification codes, and won't get
verification emails.

=item * registration_closed

true if registration new users can't register for accounts via the web

=item * private_system

true value if users must have an account to view entries

=back

=head1 METHODS

These methods are used by the setting accessors, internally:

=head2 _read_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

my $config;
sub _read_config {
	return $config if $config;

	my $config_file = Config::Auto::find_file($config_filename);
	$config = YAML::LoadFile($config_file);
}

=head2 _default

This method returns the default configuration has a hashref.

=cut

my $default = {
	css_href    => undef,
	dsn         => undef,
	email_from  => undef,
	login_class => 'Rubric::WebApp::Login::Post',
	smtp_server => undef,
	uri_root    => undef,
	private_system => undef,
	template_path  => undef,
	entries_query_class => 'Rubric::WebApp::EntriesQuery',
	registration_closed => undef,
	skip_newuser_verification => undef,
};
sub _default { $default }

=head2 make_ro_accessor

Rubric::Config isa Class::Accessor, and uses this sub to build its setting
accessors.  For a given field, it returns the value of that field in the
configuration, if it exists.  Otherwise, it returns the default for that field.

=cut

sub make_ro_accessor {
	my ($class, $field) = @_;
	sub {
		exists $class->_read_config->{$field}
			? $class->_read_config->{$field}
			: $class->_default->{$field}
	}
}

__PACKAGE__->mk_ro_accessors(keys %$default);

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
