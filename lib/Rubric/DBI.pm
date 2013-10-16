use strict;
use warnings;
package Rubric::DBI;
{
  $Rubric::DBI::VERSION = '0.154';
}

# ABSTRACT: Rubric's subclass of Class::DBI


use Rubric::Config;
use Class::DBI 0.96;
use base qw(Class::DBI);

use Class::DBI::AbstractSearch;

DBI->trace(Rubric::Config->dbi_trace_level, Rubric::Config->dbi_trace_file);

my $dsn = Rubric::Config->dsn;
my $db_user = Rubric::Config->db_user;
my $db_pass = Rubric::Config->db_pass;

__PACKAGE__->connection(
	$dsn,
	$db_user,
	$db_pass,
	{ AutoCommit => 1 }
);


sub vacuum {
	my $self = shift;
	my $dbh = $self->db_Main;
	my $pruned_links = $dbh->do(
		"DELETE FROM links WHERE id NOT IN ( SELECT link FROM entries )"
	);
}

1;

__END__

=pod

=head1 NAME

Rubric::DBI - Rubric's subclass of Class::DBI

=head1 VERSION

version 0.154

=head1 DESCRIPTION

Rubric::DBI subclasses Class::DBI.  It sets the connection by using the DSN
retrieved from Rubric::Config.

=head1 METHODS

=head2 vacuum

This method performs periodic maintenance, cleaning up records that are no
longer needed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
