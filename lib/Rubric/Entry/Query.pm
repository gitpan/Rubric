package Rubric::Entry::Query;

=head1 NAME

Rubric::Entry::Query - construct and execute a complex query

=head1 VERSION

version 0.01

 $Id: Query.pm,v 1.1 2005/01/16 03:52:46 rjbs Exp $

=cut

our $VERSION = '0.01';

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

This is the only interface to this module.  Given

=cut

sub query {
	my ($self, $arg) = @_;
	my @constraints = map { $self->get_constraint($_, $arg->{$_}) } keys %$arg;

	$self->get_entries(\@constraints);
}

sub get_constraint {
	my ($self, $param, $value) = @_;

	return unless my $code = $self->can("constraint_for_$param");
	$code->($self, $value);
}

sub get_entries {
	my ($self, $constraints) = @_;
	return Rubric::Entry->retrieve_all unless @$constraints;
	Rubric::Entry->retrieve_from_sql(
		join(" AND ", @$constraints)
		. " ORDER BY created DESC"
	);
}

sub constraint_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return "user = " . Rubric::Entry->db_Main->quote($user);
}

sub constraint_for_tags {
	my ($self, $tags) = @_;

	return unless @$tags;

	return join ' AND ',
		map { "id IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { Rubric::Entry->db_Main->quote($_) }
		@$tags;
}

sub constraint_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? "body IS NOT NULL" : "body IS NULL";
}

sub constraint_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? "link IS NOT NULL" : "link IS NULL";
}

sub constraint_for_urimd5 {
	my ($self, $md5) = @_;
	return unless my ($link) = Rubric::Link->search({ md5 => $md5 });
	return "link = " . $link->id;
}

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
				return unless my @time = _unit_from_string($datetime);
				my ($start,$end) = range_from_unit(@time);
				return
					( $prep eq 'after'  ? "$field > $end"
					: $prep eq 'before' ? "$field < $start"
					: $prep eq 'on'     ? "$field >= $start AND $field <= $end"
					: die "illegal preposition in temporal comparison" )
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
