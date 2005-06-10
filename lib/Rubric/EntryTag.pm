package Rubric::EntryTag;

=head1 NAME

Rubric::EntryTag - a tag on an entry

=head1 VERSION

 $Id: EntryTag.pm,v 1.3 2005/06/07 02:32:53 rjbs Exp $

=head1 DESCRIPTION

This class provides an interface to tags on Rubric entries.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use base qw(Rubric::DBI);

__PACKAGE__->table('entrytags');

=head1 COLUMNS

 id        - a unique identifier
 entry     - the tagged entry
 tag       - the tag itself
 tag_value - the value of the tag (for tags in "tag:value" form)

=cut

__PACKAGE__->columns(All => qw(id entry tag tag_value));

=head1 RELATIONSHIPS

=head2 entry

The entry attribute returns a Rubric::Entry.

=cut

__PACKAGE__->has_a(entry => 'Rubric::Entry');

=head1 TRIGGERS

=cut

__PACKAGE__->add_trigger(before_create => \&_nullify_values);
__PACKAGE__->add_trigger(before_update => \&_nullify_values);

sub _nullify_values {
	my $self = shift;
  $self->tag_value(undef)
    unless defined $self->{tag_value} and length $self->{tag_value};
}

=head1 METHODS

=head2 stringify_self

=cut

sub stringify_self {
  $_[0]->tag . (defined $_[0]->tag_value ? (':' . $_[0]->tag_value) : '')
}

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
