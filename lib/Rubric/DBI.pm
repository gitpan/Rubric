package Rubric::DBI;

=head1 NAME

Rubric::DBI - Rubric's subclass of Class::DBI

=head1 VERSION

 $Id: DBI.pm,v 1.2 2004/11/19 20:57:11 rjbs Exp $

=head1 DESCRIPTION

Rubric::DBI subclasses Class::DBI.  It sets the connection by using the DSN
retrieved from Rubric::Config.

=cut

use strict;
use warnings;
use Rubric::Config;
use base qw(Class::DBI);

use Class::DBI::AbstractSearch;

my $dsn = Rubric::Config->dsn;

__PACKAGE__->connection(
	$dsn,
	undef,
	undef,
	#{ AutoCommit => 0 }
);

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
