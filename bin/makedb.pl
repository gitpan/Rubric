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
	created NOT NULL,
	verification_code
);

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

CREATE TABLE entrytags (
	id INTEGER PRIMARY KEY,
	entry NOT NULL,
	tag NOT NULL,
	UNIQUE(entry, tag)
);

CREATE TABLE rubric (
	schema_version NOT NULL
);

INSERT INTO rubric (schema_version) VALUES (6);
