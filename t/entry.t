#!perl -T

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Entry"); }

{
	my $entry = Rubric::Entry->retrieve(1);

	isa_ok($entry, "Rubric::Entry");

	isa_ok($entry->link, "Rubric::Link");

	is($entry->uri, "http://rjbs.manxome.org/bryar/");
	isa_ok($entry->created, 'Time::Piece', 'created time');
	isa_ok($entry->modified, 'Time::Piece', 'modified time');
}

{
	my $entry = Rubric::Entry->create({ user => 'rjbs' });
	my $tags = Rubric::Entry->tags_from_string("test more simple");
	$entry->set_new_tags($tags);

	is($entry->link, undef);
	is($entry->uri, undef);
}

{
	my $entry = Rubric::Entry->create({
		user => 'rjbs',
		title => 'poot',
		created => 0,
		modified => 1000000000
	});

	is($entry->link, undef);
	is($entry->uri, undef);
}

{
	my $tags = Rubric::Entry->recent_tags_counted;
	isa_ok($tags, 'ARRAY', 'recent_tags_counted');
	isa_ok($tags->[0], 'ARRAY', 'recent_tags_counted->[0]');
}


