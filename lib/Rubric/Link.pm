package Rubric::Link;
use base qw(Rubric::DBI);

__PACKAGE__->table('links');

__PACKAGE__->columns(All => qw(id uri));

__PACKAGE__->has_a(
	uri => 'URI',
	deflate => sub { (shift)->canonical->as_string }
); 

__PACKAGE__->has_many(entries => 'Rubric::Entry');

sub stringify_self { $_[0]->uri->as_string }

1;
