package Rubric::Config;
use strict;
use warnings;

use Config::Auto;
use YAML;

my $config;

sub read_config {
	return $config if $config;

	my $config_file = Config::Auto::find_file('rubric.yml');
	$config = YAML::LoadFile($config_file);
}

sub dsn { (shift)->read_config->{dsn} }
sub url_root { (shift)->read_config->{url_root} }
sub css_href { (shift)->read_config->{css_href} }
sub template_path { (shift)->read_config->{template_path} }

1;
