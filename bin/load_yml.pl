use YAML;
use Rubric::Link;
use Rubric::User;

my $yaml;
{ local $/; $yaml = <>; }
my $links = YAML::Load($yaml);
my $rjbs = Rubric::User->retrieve($ARGV[0] || $ENV{USER});

foreach (@$links) {
	my $link = Rubric::Link->find_or_create({uri => $_->{href}});
	my $entry = $rjbs->add_to_entries({
		link  => $link,
		title => $_->{description},
		description => $_->{extended},
		created  => $_->{datetime},
		modified => $_->{datetime},
	});
	$entry->add_to_tags({tag => $_}) for @{$_->{tags}};
}

$rjbs->update;
