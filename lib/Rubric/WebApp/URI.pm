package Rubric::WebApp::URI;

=head1 NAME

Rubric::WebApp::URI - URIs for Rubric web requests

=head1 VERSION

 $Id: URI.pm,v 1.3 2004/11/25 05:58:54 rjbs Exp $

=head1 DESCRIPTION

This module provides methods for generating the URIs for Rubric requests.

=cut

use strict;
use warnings;

use Rubric::Config;

=head1 METHODS

=head2 root

the URI for the root of the Rubric; taken from uri_root in config

=cut

sub root { Rubric::Config->uri_root }
	
=head2 stylesheet

the URI for the stylesheet; taken from css_href in config

=cut

sub stylesheet { Rubric::Config->css_href; }

=head2 logout

URI to log out

=cut

sub logout { Rubric::Config->uri_root . '/logout' }

=head2 login

URI to form for log in

=cut

sub login { Rubric::Config->uri_root . '/login' }

=head2 entries(\%arg)

URI for entry listing; valid keys for C<%arg>:

 user - entries for one user
 tags - arrayref of tag names

=cut

sub entries {
	my ($class, $arg) = @_;
	$arg->{tags} ||= [];

	my $uri = $class->root;
	$uri .=   $arg->{user}  ? "/user/$arg->{user}"
	      : @{$arg->{tags}} ? "/tag"
	      : '';
	$uri .= ('/' . join('+', @{$arg->{tags}}) . '/') if @{$arg->{tags}};
	return $uri;
}

=head2 entry($entry)

URI to view entry

=cut

sub entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->uri_root . "/entry/" . $entry->id;
}


=head2 edit_entry($entry)

URI to edit entry

=cut

sub edit_entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->uri_root . "/edit/" . $entry->id;
}

=head2 delete_entry($entry)

URI to delete entry

=cut

sub delete_entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->uri_root . "/delete/" . $entry->id;
}

=head2 post_entry

URI for new entry form

=cut

sub post_entry { Rubric::Config->uri_root . "/post"; }

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
