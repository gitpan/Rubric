package Rubric;

=head1 NAME

Rubric - a notes and bookmarks manager with tagging

=head1 VERSION

version 0.03_02

 $Id: Rubric.pm,v 1.10 2005/01/16 04:43:23 rjbs Exp $

=cut

our $VERSION = '0.03_02';

warn "Rubric.pm isn't meant to be used.";
exit 1;

=head1 DESCRIPTION

This module is currently just a placeholder and a container for documentation.
You don't want to actually C<use Rubric>, even if you use Rubric.

Rubric is a note-keeping system that also serves as a bookmark manager.  Users
store entries, which are small (or large) notes with a set of categorizing
"tags."  Entries may also refer to URIs.

Rubric was inspired by the excellent L<http://del.icio.us/> service and the
Notational Velocity note-taking software for Mac OS.  At present, it is
primarily a del.icio.us clone, but its note-taking features will continue to
grow.  (It can also be used as a blog, which will become easier in future
iterations.)

=head1 WARNING

This is young software, likely to have bugs and likely to change in strange
ways.  I will try to keep the documented API stable, but not if it makes
writing Rubric too inconvenient.

Basically, just take note that this software is still version 0.0x; it works,
but it's still very much under construction.

=head1 INSTALLING AND UPGRADING

Consult the README file in this distribution for instructions on installation
and upgrades.

=head1 TODO

For now, consult the C<todo.html> template for future milestones, or check
L<http://rjbs.manxome.org/rubric/docs/todo>.

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

You can also find some support on the #rubric channel on Freenode IRC.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
