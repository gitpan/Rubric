package Rubric::Link;
use base qw(Rubric::DBI);

use Digest::MD5 qw(md5_hex);

__PACKAGE__->table('links');

__PACKAGE__->columns(All => qw(id uri md5));

__PACKAGE__->has_a(
	uri => 'URI',
	deflate => sub { (shift)->canonical->as_string }
); 

__PACKAGE__->has_many(entries => 'Rubric::Entry');

sub stringify_self { $_[0]->uri->as_string }

__PACKAGE__->add_trigger(before_create => \&set_md5);

sub set_md5 {
	my ($self) = @_;
	$self->_attribute_store(md5 => md5_hex("$self->{uri}"));
}

__PACKAGE__->set_sql(
	link_count => "SELECT COUNT(*) FROM entries WHERE id = ?"
);

sub link_count {
	my ($self) = @_;
	my $sth = $self->sql_link_count;
	$sth->execute($self->id);
	$sth->fetchall_arrayref->[0][0];
}

1;
