#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use Rubric::Config;

my $dbh = DBI->connect(Rubric::Config->dsn, undef, undef)
	or die "can't connect to db";

# prune dead links
print "pruning dead links: ";
my $pruned_links = $dbh->do(<<'SQL');
	DELETE FROM links
	WHERE id NOT IN (
		SELECT link FROM entries
	)
SQL

print "$pruned_links pruned\n";
