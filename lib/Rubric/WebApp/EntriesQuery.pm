package Rubric::WebApp::EntriesQuery;

=head1 NAME

Rubric::WebApp::EntriesQuery - process the /entries run method

=head1 VERSION

version 0.01

 $Id: EntriesQuery.pm,v 1.5 2005/01/14 04:06:03 rjbs Exp $

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Rubric::WebApp::EntriesQuery implements a URI parser that builds a query based
on a query URI, performs that query, and returns the rendered report on the
results.

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
	my (@constraints, %constraint);
	
	while (my $param = $webapp->next_path_part) {
		my $value = $webapp->next_path_part;
		if (my $constraint = $self->get_constraint($param, $value, $webapp)) {
			$constraint{$param} = $constraint->{param};
			push @constraints, $constraint->{sql};
		}
	}
	my $entries = $self->get_entries(\@constraints);

	$webapp->page_entries($entries)->render_entries(\%constraint);
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
	Rubric::Entry->retrieve_from_sql(
		join(" AND ", @$constraints)
		. " ORDER BY created DESC"
	);
}

sub constraint_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return {
		param => Rubric::User->retrieve($user),
		sql   => "user = " . Rubric::Entry->db_Main->quote($user),
	}
}

sub constraint_for_tags {
	my ($self, $tagstring) = @_;

	($tagstring) = ($tagstring || '') =~ /^([+\s\w\d:.*]*)$/; 
	my $tags = [ split /\+|\s/, $tagstring ];
	return unless @$tags;
	return {
		param => $tags,
		sql   => Rubric::Entry->_tags_sql(@$tags)
	}
}

sub constraint_for_has_body {
	my ($self, $bool) = @_;
	return {
		param => $bool ? "body IS NOT NULL" : "body IS NULL",
		sql   => $bool ? 1 : 0
	}
}

sub constraint_for_has_link {
	my ($self, $bool) = @_;
	return {
		param => $bool ? "link IS NOT NULL" : "link IS NULL",
		sql   => $bool ? 1 : 0
	}
}

sub constraint_for_urimd5 {
	my ($self, $md5) = @_;
	return unless my ($link) = Rubric::Link->search({ md5 => $md5 });
	return {
		param => $link,
		sql   => "link = " . $link->id
	}
}

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
				return {
					param => $datetime,
					sql   =>
						( $prep eq 'after'  ? "$field > $end"
						: $prep eq 'before' ? "$field < $start"
						: $prep eq 'on'     ? "$field >= $start AND $field <= $end"
						: die "illegal preposition in temporal comparison" )
				}
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
