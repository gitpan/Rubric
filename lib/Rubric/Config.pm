package Rubric::Config;

=head1 NAME

Rubric::Config - the configuration data for a Rubric

=head1 VERSION

 $Id: Config.pm,v 1.2 2004/11/19 20:57:11 rjbs Exp $

=head1 DESCRIPTION

Rubric::Config provides access to the configuration data for a Rubric.  The
basic implementation stores its configuration in YAML in a text file found
using Config::Auto's find_file function.

=cut

use strict;
use warnings;

use Config::Auto;
use YAML;

=head1 METHODS

=head2 read_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

my $config;
sub read_config {
	return $config if $config;

	my $config_file = Config::Auto::find_file('rubric.yml');
	$config = YAML::LoadFile($config_file);
}

=head2 dsn

This method returns the DSN to be used by Rubric::DBI to connect to the
Rubric's database.

=cut

sub dsn { (shift)->read_config->{dsn} }

=head2 url_root

This method returns the URI for the root of the Rubric::WebApp install.

=cut

sub url_root { (shift)->read_config->{url_root} }

=head2 css_href

This method returns the URI for the stylesheet to be used by Rubric::WebApp
pages.

=cut

sub css_href { (shift)->read_config->{css_href} }

=head2 template_path

This method returns the INCLUDE_PATH passed to Template when creating the
template renderer.

=cut

sub template_path { (shift)->read_config->{template_path} }

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
