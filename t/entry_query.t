#!perl

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Entry"); }

{
	my $entries = Rubric::Entry->query({
		user => Rubric::User->retrieve('eb'),
		tags => [ 'news' ],
		created_after => '2004-12-15',
		created_on    => '2005',
		created_before=> '2006-01',
		has_link => 1,
		has_body => 0
	});

	isa_ok($entries, 'Class::DBI::Iterator', '1st query result');
	cmp_ok($entries->count, '>', 0, "more than zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		urimd5 => '006d5652f4c43ab9e69328ab5e74f7e4',
		tags   => [], # empty tags list imposes no constriant
	});

	isa_ok($entries, 'Class::DBI::Iterator', '2nd query result');
	cmp_ok($entries->count, '>', 0, "more than zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		tags => [ 'perl' ],
		femptons => 10**2
	});
	isa_ok($entries, 'Class::DBI::Iterator', 'unknown query param');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}


{
	my $entries = Rubric::Entry->query({});

	isa_ok($entries, 'Class::DBI::Iterator', 'universal query result');
	cmp_ok($entries->count, '>', 0, "more than zero entries found");
}

{
	my $entries = Rubric::Entry->query({ urimd5 => 'not_an_md5sum' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (md5)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ tags => undef });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (tags 1)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ tags => 'foo' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (tags 2)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ created_on => 'last week' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (date)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		user => undef,
		has_link => 0,
		has_body => 1,
	});

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (user)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}
