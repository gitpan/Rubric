package Rubric::User;
use strict;
use warnings;
use base qw(Rubric::DBI);

__PACKAGE__->table('users');

__PACKAGE__->columns(All => qw(username password));

__PACKAGE__->has_many(entries => 'Rubric::Entry' );

__PACKAGE__->set_sql(tags_counted => <<'' );
SELECT DISTINCT tag, COUNT(*) AS count
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE user = ?)
GROUP BY tag
ORDER BY tag

sub tags_counted {
	my ($self) = @_;
	my $sth = $self->sql_tags_counted;
	$sth->execute($self);
	my $tags = $sth->fetchall_arrayref;
	return @$tags;
}

__PACKAGE__->set_sql(tags => <<'' );
SELECT DISTINCT tag
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE user = ?)
ORDER BY tag

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

sub related_tags_counted {
	my ($self, $tags) = @_;
	return unless $tags and my @tags = @$tags;

	my $query = "
	SELECT DISTINCT tag, COUNT(*) AS count
	FROM entrytags
	WHERE entry IN (SELECT id FROM entries WHERE user = ?) AND 
	tag NOT IN (" . join(',',map { $self->db_Main->quote($_) } @tags) . ")
	AND ";

	$query .= 
		join ' AND ',
		map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { $self->db_Main->quote($_) }
		@tags;
	$query .= " GROUP BY tag";

	my $result = $self->db_Main->selectall_arrayref($query, undef, $self);
	@$result;
}

sub quick_entry {
	my ($self, $entry) = @_;

	return unless $entry->{uri} and $entry->{title};
	$entry->{tags} = [ grep /\w+/, split /\s+/, $entry->{tags} ];

	my $link = Rubric::Link->find_or_create({ uri => $entry->{uri} });

	my $new_entry = Rubric::Entry->find_or_create({
		link => $link,
		user => $self->param('current_user')
	});

	$new_entry->title($entry->{title});
	$new_entry->description($entry->{description});
	$new_entry->update;
	$new_entry->set_new_tags($entry->{tags});

	return $entry;
}

1;
