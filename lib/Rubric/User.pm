package Rubric::User;

=head1 NAME

Rubric::User - a Rubric user

=head1 VERSION

 $Id: User.pm,v 1.10 2004/11/28 03:14:34 rjbs Exp $

=head1 DESCRIPTION

This class provides an interface to Rubric users.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use strict;
use warnings;
use base qw(Rubric::DBI);

__PACKAGE__->table('users');

=head1 COLUMNS

 username - the user's login name
 password - the hex md5sum of the user's password
 email    - the user's email address
 validation_code - the code sent to the user for validation; NULL if validated

=cut

__PACKAGE__->columns(All => qw(username password email validation_code));

=head1 RELATIONSHIPS

=head2 entries

Every user has_many entries, which are Rubric::Entry objects.  They can be
retrieved with the C<entries> accessor, as usual.

=cut

__PACKAGE__->has_many(entries => 'Rubric::Entry' );

=head2 tags

A user has as "his" tags all the tags that occur on his entries.  There exist a
number of accessors for his tag list.

=head3 tags

This returns an arrayref of all the user's tags in their database colation order.

=cut

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
	[ map { @$_ } @$tags ];
}

=head3 tags_counted

This returns an arrayref of arrayrefs, each containing a tag name and the
number of entries tagged with that tag.  The pairs are sorted in colation order
by tag name.

=cut

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
	return $tags;
}

=head3 related_tags(\@tags)

This method returns a reference to an array of tags related to all the given
tags.  Tags are related if they occur together on entries.  

=cut

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
}

=head3 related_tags_counted(\@tags)

This is the obvious conjunction of C<related_tags> and C<tags_counted>.  It
returns an arrayref of arrayrefs, each a pair of tag/occurance values.

=cut

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
}

=head1 METHODS

=head2 quick_entry(\%entry)

This method creates or udpates an entry for the user.  The passed entry should
include the following data:

 uri         - the URI for the entry
 tags        - the tags for the entry, as a space delimited string
 title       - the title for the entry
 description - the description for the entry
 body        - the body for the entry

If an entry for the link exists, it is updated.  Existing tags are replaced
with the new tags.  If no entry exists, the Rubric::Link is created if needed,
and a new entry is then created.

The Rubric::Entry object is returned.

=cut

sub quick_entry {
	my ($self, $entry) = @_;

	return unless $entry->{title};
	$entry->{tags} = [ grep /\w+/, split /\s+/, $entry->{tags} ];

	my $link = Rubric::Link->find_or_create({ uri => $entry->{uri} })
		if $entry->{uri};

	return unless my $new_entry = $entry->{entryid}
		? Rubric::Entry->retrieve($entry->{entryid})
		: $entry->{uri}
			? Rubric::Entry->find_or_create({ link => $link, user => $self })
			: Rubric::Entry->create({ user => $self });

	$new_entry->title($entry->{title});
	$new_entry->description($entry->{description});
	$new_entry->body($entry->{body} || undef);
	$new_entry->update;
	$new_entry->set_new_tags($entry->{tags});

	return $entry;
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
