#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use Rubric::Config;

unlink('rubric.db');

my $dbh = DBI->connect(Rubric::Config->dsn,undef,undef);

{
	local $/ = "\n\n";
	$dbh->do($_) for <DATA>;
}

__DATA__
CREATE TABLE links (
	id INTEGER PRIMARY KEY,
	uri varchar UNIQUE NOT NULL,
	md5 varchar NOT NULL
);

CREATE TABLE users (
	username PRIMARY KEY,
	password NOT NULL,
	email NOT NULL,
	validation_code
);

CREATE TABLE entries (
	id INTEGER PRIMARY KEY,
	link integer NOT NULL,
	user varchar NOT NULL,
	title varchar NOT NULL,
	created NOT NULL,
	modified NOT NULL,
	description varchar
);

CREATE TABLE entrytags (
	id INTEGER PRIMARY KEY,
	entry NOT NULL,
	tag NOT NULL,
	UNIQUE(entry, tag)
);
