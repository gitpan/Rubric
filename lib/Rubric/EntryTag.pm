package Rubric::EntryTag;
use base qw(Rubric::DBI);

__PACKAGE__->table('entrytags');

__PACKAGE__->columns(All => qw(id entry tag));

__PACKAGE__->has_a(entry => 'Rubric::Entry');

1;
