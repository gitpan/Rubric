use Rubric::Link;
use Rubric::User;

use Digest::MD5 qw(md5_hex);

my @uris = (
	'http://www.cnn.com/',
	'http://www.cnn.com',
	'http://rjbs.manxome.org/bryar/bryar.cgi'
);

for (@uris) {
	my $uri = URI->new($_);
	my $link = Rubric::Link->find_or_create({
		uri => $uri->canonical
	});
	print $link->id, " - ", $link->uri, "\n";
}

Rubric::User->create({ username => 'rjbs', password => md5_hex('pswd') });
Rubric::User->create({ username => 'mdxi', password => md5_hex('password') });
Rubric::User->create({ username => 'jcap', password => md5_hex('password') });

for my $user (Rubric::User->retrieve_all) {
	$user->add_to_entries({
		link  => 2,
		title => "rjbs' journal",
		created  => time - int(rand(5000000)),
		modified => time,
	})->add_to_tags({tag => 'blog'});
}
