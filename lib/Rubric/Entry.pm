package Rubric::Entry;
use base qw(Rubric::DBI);
use Time::Piece;

__PACKAGE__->table('entries');

__PACKAGE__->columns(All => qw(id link user title description created modified));

__PACKAGE__->has_a(link => 'Rubric::Link');
__PACKAGE__->has_a(user => 'Rubric::User');

__PACKAGE__->has_a($_ => 'Time::Piece', deflate => 'epoch')
	for qw(created modified);

__PACKAGE__->has_many(entrytags => 'Rubric::EntryTag' );
__PACKAGE__->has_many(tags => [ 'Rubric::EntryTag' => tag ]);

__PACKAGE__->add_trigger(before_create => \&default_title);

__PACKAGE__->add_trigger(before_create => \&create_times);
__PACKAGE__->add_trigger(before_update => \&update_times);

sub default_title {
	my $self = shift;
	$self->title('(default)') unless $self->{title}
}

sub create_times {
	my $self = shift;
	$self->created(scalar gmtime) unless $self->{created};
	$self->modified(scalar gmtime) unless $self->{modified};
}

sub update_times {
	my $self = shift;
	$self->modified(scalar gmtime);
}

sub by_tag {
	my ($self, $arg) = @_;
	my %wheres;
	if ($arg->{user}) { $wheres{user} = $arg->{user} }
	if ($arg->{tags} and my @tags = @{$arg->{tags}}) {
		$_ = $self->db_Main->quote($_) for @tags;
		my $ids = 
			join ' AND ',
			map { "id IN (SELECT entry FROM entrytags WHERE tag=$_)" }
			@tags;
		$wheres{''} = \$ids;
	}
	%wheres
		? $self->search_where(\%wheres, { order_by => "created DESC" })
		: $self->retrieve_all;
}

sub set_new_tags {
	my ($self, $tags) = @_;
	$self->entrytags->delete_all;
	$self->update;

	$self->add_to_tags({ tag => $_ }) for @$tags;
}

__PACKAGE__->set_sql(RetrieveAll => <<'');
SELECT __ESSENTIAL__
FROM   __TABLE__
ORDER BY created DESC

__PACKAGE__->set_sql(recent_tags => <<'');
SELECT tag, COUNT(*) as count
FROM   entrytags
WHERE
	entry IN (SELECT id FROM entries WHERE created > ? LIMIT 100)
GROUP BY tag
ORDER BY count DESC
LIMIT 50

sub recent_tags_counted {
	my ($class) = @_;
	my $sth = $class->sql_recent_tags;
	$sth->execute(time - (86400 * 7));
	my $result = $sth->fetchall_arrayref;
	return @$result;
}

1;
