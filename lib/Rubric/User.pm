package Rubric::User;
use strict;
use warnings;
use base qw(Rubric::DBI);

__PACKAGE__->table('users');

__PACKAGE__->columns(All => qw(username password));

__PACKAGE__->has_many(entries => 'Rubric::Entry' );

__PACKAGE__->set_sql(tags => <<'' );
SELECT DISTINCT tag
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE user = ?)

sub tags {
	my ($self) = @_;
	my $sth = $self->sql_tags;
	$sth->execute($self);
	my $tags = $sth->fetchall_arrayref;
	map { @$_ } @$tags;
}

sub related_tags {
	my ($self, $tags) = @_;
	return unless $tags and my @tags = @$tags;

	my $query = "
	SELECT DISTINCT tag FROM entrytags
	WHERE entry IN (SELECT id FROM entries WHERE user = ?) AND 
	tag NOT IN (" . join(',',map { $self->db_Main->quote($_) } @tags) . ")
	AND ";

	$query .= 
		join ' AND ',
		map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { $self->db_Main->quote($_) }
		@tags;

	my $result = $self->db_Main->selectcol_arrayref($query, undef, $self);
	@$result;
}

1;
