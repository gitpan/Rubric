package Rubric::WebApp::EntriesQuery;

=head1 NAME

Rubric::WebApp::EntriesQuery - process the /entries run method

=head1 VERSION

version 0.01

 $Id: EntriesQuery.pm,v 1.2 2005/01/03 23:39:07 rjbs Exp $

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Rubric::WebApp::EntriesQuery implements a URI parser that builds a query based
on a query URI, performs that query, and returns the rendered report on the
results.

=cut

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
	my @constraints;
	
	while (my $param = $webapp->next_path_part) {
		if (my $sql =  $self->get_constraint($param, $webapp->next_path_part)) {
			push @constraints, $sql;
		}
	}
	my $entries = $self->get_entries(\@constraints);

	$webapp->page_entries($entries)->render_entries;
}

sub get_constraint {
	my ($self, $param, $value) = @_;
	my $constraint;

	return unless my $code = $self->can("constraint_for_$param");
	return unless defined $value;

	$constraint = $code->($self, $value);
}

sub get_entries {
	my ($self, $constraints) = @_;
	return Rubric::Entry->retrieve_all unless @$constraints;
	Rubric::Entry->retrieve_from_sql(join(" AND ", @$constraints));
}

sub constraint_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return "user = " . Rubric::Entry->db_Main->quote($user);
}

sub constraint_for_body {
	my ($self, $bool) = @_;
	return $bool ? "body IS NOT NULL" : "body IS NULL";
}

sub constraint_for_link {
	my ($self, $bool) = @_;
	return $bool ? "link IS NOT NULL" : "link IS NULL";
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
