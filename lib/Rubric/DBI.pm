package Rubric::DBI;
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

1;
