#!perl

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::User"); }

{
	my $user = Rubric::User->retrieve('eb');
	isa_ok($user, 'Rubric::User');
	isa_ok($user->tags, 'ARRAY', 'user tag list');
	isa_ok($user->tags_counted, 'ARRAY', 'tags_counted');
	isa_ok($user->tags_counted->[0], 'ARRAY', 'tags_counted->[0]');
	isa_ok($user->related_tags(['news']), 'ARRAY', 'related_tags');
	isa_ok(
		$user->related_tags_counted(['news']),
		'ARRAY',
		'related_tags_counted'
	);
	isa_ok(
		$user->related_tags_counted(['news'])->[0],
		'ARRAY',
		'related_tags_counted->[0]'
	);

	is($user->related_tags(), undef, "nothing relates to nothing");
	is($user->related_tags([]), undef, "nothing relates to nothingref");
	is(
		$user->related_tags_counted(),
		undef,
		"nothing relates to nothing (counted)"
	);
	is(
		$user->related_tags_counted([]),
		undef,
		"nothing relates to nothingref (counted)"
	);

	my $entry = $user->quick_entry({
		title => "Quick Entry!!",
		link  => "http://www.quick.com/",
		tags  => [qw(quick entry test)]
	});
}

{
	my $user = Rubric::User->create({
		username => 'testy',
		password => '12345', # not an md5sum
		email    => 'test@example.com',
		verification_code => '12345'
	});

	isa_ok($user, 'Rubric::User', 'newly created user');
	ok($user->verification_code, "user isn't verified");
	is($user->verify(), undef, "verify w/o code");
	ok($user->verification_code, "user still isn't verified");
	is($user->verify('54321'), undef, "verify w/wrong code");
	ok($user->verification_code, "user still isn't verified");
	is($user->verify('12345'), 1, "verify w/correct code");
	is($user->verification_code, undef, "user is verified");
	is($user->verify('12345'), undef, "verify when already verified");

	$user->delete;
}

{
	my $user = Rubric::User->create({
		username => 'testo',
		password => '12345', # not an md5sum
		created  => 0,
		email    => 'stetson@example.com',
	});

	isa_ok($user, 'Rubric::User', 'newly created user');
	is($user->verification_code, undef, "user is verified");

	is($user->quick_entry({}), undef, "can't create title-less entry");
	isa_ok(
		$user->quick_entry({ title => 'foolink', uri => 'http://foo.com/' }),
		'Rubric::Entry',
		'quick entry with link'
	);
	
	my $entry = $user->quick_entry(
		{ title => 'foo-link', uri => 'http://foo.com/' }
	);
	isa_ok( $entry, 'Rubric::Entry', 'quick entry with link (update/uri)');

	isa_ok(
		$user->quick_entry({ entryid => $entry->id, title => 'fool ink' }),
		'Rubric::Entry',
		'quick entry with link (update/id)'
	);

	isa_ok(
		$user->quick_entry({ title => 'foo', body => 'snowdens of yesteryear' }),
		'Rubric::Entry',
		'quick entry without link'
	);

	$user->delete;
}
