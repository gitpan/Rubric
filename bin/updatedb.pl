#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use Rubric::Config;

my $dbh = DBI->connect(
	Rubric::Config->dsn,
	Rubric::Config->db_user,
	Rubric::Config->db_pass,
	{PrintError => 0}
) or die "can't connect to db";

sub determine_version {
	my ($version) = $dbh->selectrow_array("SELECT schema_version FROM rubric");
	return $version if $version;

	{
		my @columns = $dbh->selectrow_array("SELECT * FROM entries LIMIT 1");
		return 4 if @columns == 8; # v4 added body column;
	}

	{
		my @columns = $dbh->selectrow_array("SELECT * FROM users LIMIT 1");
		return 3 if @columns == 4; # v3 added email and validation_code;
	}

	{
		my @columns = $dbh->selectrow_array("SELECT * FROM links LIMIT 1");
		return 2 if @columns == 3; # v2 added md5 column;
	}

	{
		my @columns = $dbh->selectrow_array("SELECT * FROM links LIMIT 1");
		return 1 if @columns == 2;
	}

	die "can't determine db schema version" unless $version;
}

sub last_version { sub { 
	print "now at current schema!\n";
	exit;
} }

my %from;

# from 1 to 2
#  add md5 sum to links table

$from{1} = sub {
	require Digest::MD5;
	$dbh->func('md5hex', 1, \&Digest::MD5::md5_hex, 'create_function');

	my $sql = <<'END_SQL';
	CREATE TABLE new_links (
		id INTEGER PRIMARY KEY,
		uri varchar UNIQUE NOT NULL,
		md5 varchar NOT NULL
	);

	INSERT INTO new_links
	SELECT id, uri, md5hex(uri) FROM links;

	DROP TABLE links;

	CREATE TABLE links (
		id INTEGER PRIMARY KEY,
		uri varchar UNIQUE NOT NULL,
		md5 varchar NOT NULL
	);

	INSERT INTO links
	SELECT id, uri, md5 FROM new_links;

	DROP TABLE new_links;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 2 to 3
#  add email and validation_code
#  fill in email with garbage data

$from{2} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		validation_code
	);

	INSERT INTO new_users
	SELECT *, 'user@example.com', NULL FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		validation_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 3 to 4
#  link becomes null-ok
#  add body column

$from{3} = sub {
	my $sql = <<END_SQL;
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
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 4 to 5
#  add rubric table and schema number

$from{4} = sub {
	my $sql = <<END_SQL;
	CREATE TABLE rubric (
		schema_version NOT NULL
	);

	INSERT INTO rubric (schema_version) VALUES (5);
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 5 to 6
#  add "created" column to users

$from{5} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		validation_code
	);

	INSERT INTO new_users
	SELECT username, password, email, 0, validation_code
	FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		validation_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;

	UPDATE rubric SET schema_version = 6;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 6 to 7
#  validation_code is now verification_code

$from{6} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code
	);

	INSERT INTO new_users
	SELECT username, password, email, 0, validation_code
	FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;

	UPDATE rubric SET schema_version = 7;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

$from{7} = last_version;

while ($_ = determine_version) {
	print "updating from version $_...\n";
	die "no update path from schema version $_" unless $from{$_};
	$from{$_}->();
}
