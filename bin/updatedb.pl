#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use Rubric::Config;

my $dbh = DBI->connect(Rubric::Config->dsn,undef,undef) or die;

{
	local $/ = "\n\n";
	$dbh->do($_) for <DATA>;
}

__DATA__
CREATE TABLE new_entries (
	id INTEGER PRIMARY KEY,
	link integer,
	user varchar NOT NULL,
	title varchar NOT NULL,
	created NOT NULL,
	modified NOT NULL,
	description varchar,
	body TEXT
);

INSERT INTO new_entries
SELECT *, NULL FROM entries;

DROP TABLE entries;

CREATE TABLE entries (
	id INTEGER PRIMARY KEY,
	link integer,
	user varchar NOT NULL,
	title varchar NOT NULL,
	created NOT NULL,
	modified NOT NULL,
	description varchar,
	body TEXT
);

INSERT INTO entries
SELECT * FROM new_entries;

DROP TABLE new_entries;
