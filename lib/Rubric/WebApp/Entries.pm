package Rubric::WebApp::Entries;

=head1 NAME

Rubric::WebApp::Entries - process the /entries run method

=head1 VERSION

version 0.04

 $Id: Entries.pm,v 1.9 2005/01/24 04:19:59 rjbs Exp $

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

Rubric::WebApp::Entries implements a URI parser that builds a query based
on a query URI, passes it to Rubric::Entries, and returns the rendered report
on the results.

=cut

use Date::Span;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;

=head1 METHODS

=head2 entries($webapp)

This method is called by Rubric::WebApp.  It returns the rendered template for
return to the user's browser.

=cut

sub entries {
	my ($self, $webapp) = @_;
	my %arg;
	
	while (my $param = $webapp->next_path_part) {
		my $value = $webapp->next_path_part;
		$arg{$param} = $self->get_arg($param, $value);
	}
	$webapp->param(recent_tags => Rubric::Entry->recent_tags_counted)
		unless %arg;
	my $entries = Rubric::Entry->query(\%arg);

	$webapp->page_entries($entries)->render_entries(\%arg);
}

=head2 get_arg($param => $value)

Given a name/value pair from the path, this method will attempt to
generate part of hash to send to << Rubric::Entry->query >>.  To do this, it
looks for and calls a method called "arg_for_NAME" where NAME is the passed
value of C<$param>.  If no clause can be generated, it returns undef.

=cut

sub get_arg {
	my ($self, $param, $value) = @_;

	return undef unless my $code = $self->can("arg_for_$param");
	$code->($self, $value);
}

=head2 arg_for_NAME

Each of these functions returns the proper value to put in the hash passed to
C<< Rubric::Entries->query >>.  If given an invalid argument, they will return
undef.

=head3 arg_for_user($username)

Given a username, this method returns the associated Rubric::User object.

=cut

sub arg_for_user {
	my ($self, $user) = @_;
	return undef unless $user;
	return Rubric::User->retrieve($user) || undef;
}

=head3 arg_for_tags($tagstring)

Given "happy fuzzy bunnies" this returns C< [ qw(happy fuzzy bunnies) ] >

=cut

sub arg_for_tags {
	my ($self, $tagstring) = @_;

	($tagstring) = ($tagstring || '') =~ /^([+\s\w\d:.*]*)$/; 
	my $tags = [ split /\+|\s/, $tagstring ];
	return $tags;
}

=head3 arg_for_has_body($bool)

Returns the given boolean as 0 or 1.

=cut

sub arg_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

=head3 arg_for_has_link($bool)

Returns the given boolean as 0 or 1.

=cut

sub arg_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

=head3 arg_for_urimd5($md5sum)

This method returns the passed value, if that value is a valid 16-character
md5sum.

=cut

sub arg_for_urimd5 {
	my ($self, $md5) = @_;
	return undef unless $md5 =~ /\A[a-z0-9]{32}\Z/i;
	return $md5;
}

=head3 arg_for_{timefield}_{preposition}($datetime)

These methods correspond to those described in L<Rubric::Entry::Query>.

They return the passed string unchanged.

=cut

## more date-arg handling code
{
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"arg_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
				return $datetime;
			}
		}
	}
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
