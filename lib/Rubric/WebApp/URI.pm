package Rubric::WebApp::URI;

=head1 NAME

Rubric::WebApp::URI - URIs for Rubric web requests

=head1 VERSION

 $Id: URI.pm,v 1.2 2004/11/25 03:29:26 rjbs Exp $

=head1 DESCRIPTION

This module provides methods for generating the URLs for Rubric requests.

=cut

use strict;
use warnings;

use Rubric::Config;

=head1 METHODS

=head2 root

=cut

sub root { Rubric::Config->url_root }
	
=head2 stylesheet

=cut

sub stylesheet { Rubric::Config->css_href; }

=head2 logout

=cut

sub logout { Rubric::Config->url_root . '/logout' }

=head2 login

=cut

sub login { Rubric::Config->url_root . '/login' }

=head2 entries

=cut

sub entries {
	my ($class, $arg) = @_;
	$arg->{tags} ||= [];

	my $url = $class->root;
	$url .=   $arg->{user}  ? "/user/$arg->{user}"
	      : @{$arg->{tags}} ? "/tag"
	      : '';
	$url .= ('/' . join('+', @{$arg->{tags}}) . '/') if @{$arg->{tags}};
	return $url;
}

=head2 entry

=cut

sub entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->url_root . "/entry/" . $entry->id;
}


=head2 edit_entry

=cut

sub edit_entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->url_root . "/edit/" . $entry->id;
}

=head2 delete_entry

=cut

sub delete_entry {
	my ($class, $entry) = @_;
	return unless UNIVERSAL::isa($entry,  'Rubric::Entry');

	return Rubric::Config->url_root . "/delete/" . $entry->id;
}

=head2 post_entry

=cut

sub post_entry { Rubric::Config->url_root . "/post"; }

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
