package Rubric::WebApp::EntriesQuery;

=head1 NAME

Rubric::WebApp::EntriesQuery - process the /entries run method

=head1 VERSION

version 0.01

 $Id: Entries.pm,v 1.1 2005/01/16 03:52:46 rjbs Exp $

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Rubric::WebApp::EntriesQuery implements a URI parser that builds a query based
on a query URI, performs that query, and returns the rendered report on the
results.

=cut

use Date::Span;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;

=head1 METHODS

=head2 entries($webapp)

This method is called by Rubric::WebApp.  It returns the rendered template for
return to the user's browser.

=cut

sub entries {
	my ($self, $webapp) = @_;
	my %arg;
	
	while (my $param = $webapp->next_path_part) {
		my $value = $webapp->next_path_part;
		if (my $arg = $self->get_arg($param, $value)) {
			$arg{$param} = $arg;
		}
	}
	my $entries = Rubric::Entry->query(\%arg);

	$webapp->page_entries($entries)->render_entries(\%arg);
}

sub get_arg {
	my ($self, $param, $value) = @_;

	return unless my $code = $self->can("arg_for_$param");
	$code->($self, $value);
}

sub arg_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return Rubric::User->retrieve($user),
}

sub arg_for_tags {
	my ($self, $tagstring) = @_;

	($tagstring) = ($tagstring || '') =~ /^([+\s\w\d:.*]*)$/; 
	my $tags = [ split /\+|\s/, $tagstring ];
	return $tags;
}

sub arg_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

sub arg_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

sub arg_for_urimd5 {
	my ($self, $md5) = @_;
	return unless my ($link) = Rubric::Link->search({ md5 => $md5 });
	return $link;
}

## more date-arg handling code
{
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"arg_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
				return $datetime;
			}
		}
	}
}

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
