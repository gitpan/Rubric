package Rubric::Entry::Query;

=head1 NAME

Rubric::Entry::Query - construct and execute a complex query

=head1 VERSION

version 0.04

 $Id: Query.pm,v 1.6 2005/03/31 01:02:53 rjbs Exp $

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

Rubric::Entry::Query builds a query based on a simple hash of parameters,
performs that query, and returns the rendered report on the results.

=cut

use Date::Span;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Rubric::Config;

=head1 METHODS

=head2 query(\%arg)

This is the only interface to this module.  Given a hashref of named arguments,
it returns the entries that match constraints built from the arguments.  It
generates these constraints with C<get_constraint> and its helpers.  If any
constraint is invalid, an empty set of results is returned.

=cut

sub query {
	my ($self, $arg, $user) = @_;
	my @constraints = map { $self->get_constraint($_, $arg->{$_}) } keys %$arg;
	@constraints = ("1 = 0") if grep { not defined } @constraints;

	$self->get_entries(\@constraints);
}

=head2 get_constraint($param => $value)

Given a name/value pair describing a constraint, this method will attempt to
generate part of an SQL WHERE clause enforcing the constraint.  To do this, it
looks for and calls a method called "constraint_for_NAME" where NAME is the
passed value of C<$param>.  If no clause can be generated, it returns undef.

=cut

sub get_constraint {
	my ($self, $param, $value) = @_;

	return undef unless my $code = $self->can("constraint_for_$param");
	$code->($self, $value);
}

=head2 get_entries(\@constraints)

Given a set of SQL constraints, this method builds the WHERE and ORDER BY
clauses and performs a query with Class::DBI's C<retrieve_from_sql>.

=cut

sub get_entries {
	my ($self, $constraints) = @_;
	return Rubric::Entry->retrieve_all unless @$constraints;
	Rubric::Entry->retrieve_from_sql(
		join(" AND ", @$constraints)
		. " ORDER BY created DESC"
	);
}

=head2 constraint_for_NAME

These methods are called to produce SQL for the named parameter, and are passed
a scalar argument.  If the argument is not valid, they return undef, which will
cause C<query> to produce an empty set of records.

=head3 constraint_for_user($user)

Given a Rubric::User object, this returns SQL to limit results to entries by
the user.

=cut

sub constraint_for_user {
	my ($self, $user) = @_;
	return undef unless $user;
	return "user = " . Rubric::Entry->db_Main->quote($user);
}

=head3 constraint_for_tags(\@tags)

Given an arrayref of tag names, this returns SQL to limit results to entries
marked with the given tags.

=cut

sub constraint_for_tags {
	my ($self, $tags) = @_;

	return undef unless $tags and ref $tags eq 'ARRAY';
	return unless @$tags;

	return join ' AND ',
		map { "id IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { Rubric::Entry->db_Main->quote($_) }
		@$tags;
}

=head3 constraint_for_has_body($bool)

This returns SQL to limit the results to entries with bodies.

=cut

sub constraint_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? "body IS NOT NULL" : "body IS NULL";
}

=head3 constraint_for_has_link($bool)

This returns SQL to limit the results to entries with links.

=cut

sub constraint_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? "link IS NOT NULL" : "link IS NULL";
}

=head3 constraint_for_urimd5($md5)

This returns SQL to limit the results to entries whose link has the given
md5sum.

=cut

sub constraint_for_urimd5 {
	my ($self, $md5) = @_;
	return undef unless my ($link) = Rubric::Link->search({ md5 => $md5 });
	return "link = " . $link->id;
}

=head3 constraint_for_{timefield}_{preposition}($datetime)

This set of six methods return SQL to limit the results based on its
timestamps.

The passed value is a complete or partial datetime in the form:

 YYYY[-MM[-DD[ HH[:MM]]]]  # space may be replaced with 'T'

The timefield may be "created" or "modified".

The prepositions are as follows:

 after  - after the latest part of the given unit of time
 before - before the earliest part of the given unit of time
 on     - after (or at) the earliest part and before (or at) the latest part

=cut

## here there be small lizards
## date parameter handling below...

sub _unit_from_string {
	my ($datetime) = @_;
	return unless my @unit = $datetime =~ 
		qr/^(\d{4})(?:-(\d{2})(?:-(\d{2})(?:(?:T|)(\d{2})(?::(\d{2}))?)?)?)?$/o;
	$unit[1]-- if $unit[1];
	return @unit;
}

{
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"constraint_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
				return undef unless my @time = _unit_from_string($datetime);
				my ($start,$end) = range_from_unit(@time);
				return
					( $prep eq 'after'  ? "$field > $end"
					: $prep eq 'before' ? "$field < $start"
					:                     "$field >= $start AND $field <= $end")
#					: $prep eq 'on'     ? "$field >= $start AND $field <= $end"
#					: die "illegal preposition in temporal comparison" )
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
