package Rubric::EntryTag;

=head1 NAME

Rubric::EntryTag - a tag on an entry

=head1 VERSION

 $Id: EntryTag.pm,v 1.2 2004/11/19 20:57:11 rjbs Exp $

=head1 DESCRIPTION

This class provides an interface to tags on Rubric entries.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use base qw(Rubric::DBI);

__PACKAGE__->table('entrytags');

=head1 COLUMNS

 id    - a unique identifier
 entry - the tagged entry
 tag   - the tag itself

=cut

__PACKAGE__->columns(All => qw(id entry tag));

=head1 RELATIONSHIPS

=head2 entry

The entry attribute returns a Rubric::Entry.

=cut

__PACKAGE__->has_a(entry => 'Rubric::Entry');

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
