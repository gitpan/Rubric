package Rubric::WebApp::Entries;

=head1 NAME

Rubric::WebApp::Entries - process the /entries run method

=head1 VERSION

version 0.04

 $Id: Entries.pm,v 1.7 2005/01/20 20:58:59 rjbs Exp $

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

Rubric::WebApp::Entries implements a URI parser that builds a query based
on a query URI, passes it to Rubric::Entries, and returns the rendered report
on the results.

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
		$arg{$param} = $self->get_arg($param, $value);
	}
	$webapp->param(recent_tags => Rubric::Entry->recent_tags_counted)
		unless %arg;
	my $entries = Rubric::Entry->query(\%arg);

	$webapp->page_entries($entries)->render_entries(\%arg);
}

sub get_arg {
	my ($self, $param, $value) = @_;

	return undef unless my $code = $self->can("arg_for_$param");
	$code->($self, $value);
}

sub arg_for_user {
	my ($self, $user) = @_;
	return undef unless $user;
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
	return undef unless my ($link) = Rubric::Link->search({ md5 => $md5 });
	return $link->md5;
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
