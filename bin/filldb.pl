use Rubric::Link;
use Rubric::User;

use Digest::MD5 qw(md5_hex);

my @uris = (
	'http://www.cnn.com/',
	'http://www.cnn.com',
	'http://rjbs.manxome.org/bryar/'
);

for (@uris) {
	my $uri = URI->new($_);
	my $link = Rubric::Link->find_or_create({ uri => $uri->canonical });
}

Rubric::User->create({
	username => 'jjj',
	email    => 'jjj@bugle.bz',
	password => md5_hex('yellow')
});
Rubric::User->create({
	username => 'eb',
	email    => 'eddie@brock.net',
	password => md5_hex('black')
});
Rubric::User->create({
	username => 'mxlptlyk',
	email    => 'mister_m@5th.dim',
	password => md5_hex('kyltplxm')
});

for my $user (Rubric::User->retrieve_all) {
	$user->add_to_entries({
		link  => 2,
		title => "rjbs' journal",
		created  => time - int(rand(5000000)),
		modified => time,
	})->add_to_tags({tag => 'blog'});
}

Rubric::User->retrieve('eb')->add_to_entries({
	link  => 1,
	title => "CNN: This is CNN",
})->add_to_tags({ tag => 'news' });

Rubric::User->retrieve('eb')->quick_entry({
	uri   => "http://news.bbc.co.uk/",
	title => "BBC News",
	tags  => "news bbc"
});

Rubric::User->retrieve('mxlptlyk')->quick_entry({
	uri   => "http://www.dccomics.com/",
	title => "DC Comics",
	description => "they print lies!",
	tags  => "news lies comics"
});
