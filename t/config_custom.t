#!perl -T

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 'rubric.yml'); }

my %config = (
	css_href    => undef,
	dsn         => 'dbi:SQLite:dbname=t/db/rubric.db',
	email_from  => undef,
	login_class => 'Rubric::WebApp::Login::Post',
	smtp_server => undef,
	uri_root    => undef,
	private_system => undef,
	template_path  => 'templates',
	entries_query_class => 'Rubric::WebApp::Entries',
	registration_closed => undef,
	skip_newuser_verification => undef,
);

is(Rubric::Config->$_, $config{$_}, "value of $_")
	for (keys %config);

