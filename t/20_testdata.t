#!perl -T
use Test::More tests => 14;

use_ok('Rubric::Link');
use_ok('Rubric::User');

use Digest::MD5 qw(md5_hex);

my @uris = (
	'http://www.cnn.com/',
	'http://www.cnn.com',
	'http://rjbs.manxome.org/bryar/'
);

ok(Rubric::Link->find_or_create({ uri => URI->new($_)->canonical })) for @uris;

my @users = (
	{ username => 'jjj',      email => 'jjj@bugle.bz',  password => md5_hex('yellow')  },
	{ username => 'eb',       email => 'ed@brock.name', password => md5_hex('black')   },
	{ username => 'mxlptlyk', email => 'mr_m@5th.dim',  password => md5_hex('kyltplxm')},
);

ok(Rubric::User->create($_)) for (@users);

for my $user (Rubric::User->retrieve_all) {
	ok(
		$user->add_to_entries({
			link  => 2,
			title => "rjbs' journal",
			created  => time - int(rand(5000000)),
			modified => time,
		})->add_to_tags({tag => 'blog'})
	);
}

ok(
	Rubric::User->retrieve('eb')->add_to_entries({
		link  => 1,
		title => "CNN: This is CNN",
	})->add_to_tags({ tag => 'news' })
);

ok(
	Rubric::User->retrieve('eb')->quick_entry({
		uri   => "http://news.bbc.co.uk/",
		title => "BBC News",
		tags  => "news bbc"
	})
);

ok(
	Rubric::User->retrieve('mxlptlyk')->quick_entry({
		uri   => "http://www.dccomics.com/",
		title => "DC Comics",
		description => "they print lies!",
		tags  => "news lies comics"
	})
);
