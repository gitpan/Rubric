package Rubric::Entry;
use base qw(Rubric::DBI);

__PACKAGE__->table('entries');

__PACKAGE__->columns(All => qw(id link user title description created modified));

__PACKAGE__->has_a(link => 'Rubric::Link');
__PACKAGE__->has_a(user => 'Rubric::User');

__PACKAGE__->has_a($_ => 'Time::Piece', deflate => 'epoch')
	for qw(created modified);

__PACKAGE__->has_many(entrytags => 'Rubric::EntryTag' );
__PACKAGE__->has_many(tags => [ 'Rubric::EntryTag' => tag ]);

__PACKAGE__->add_trigger(before_create => \&title_default);
__PACKAGE__->add_trigger(before_update => \&title_default);

__PACKAGE__->add_trigger(before_create => \&create_times);
__PACKAGE__->add_trigger(before_update => \&update_times);

sub title_default {
	my $self = shift;
	$self->title($self->{title} || 'default');
}

sub create_times {
	my $self = shift;
	$self->created(time) unless $self->{created};
	$self->modified(time) unless $self->{modified};
}

sub update_times {
	my $self = shift;
	$self->modified(gmtime);
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

__PACKAGE__->set_sql(RetrieveAll => <<'');
SELECT __ESSENTIAL__
FROM   __TABLE__
ORDER BY created DESC

1;
