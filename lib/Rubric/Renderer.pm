package Rubric::Renderer;

=head1 NAME

Rubric::Renderer - the rendering interface for Rubric

=head1 VERSION

 $Id: Renderer.pm,v 1.4 2004/12/14 04:30:54 rjbs Exp $

=head1 DESCRIPTION

Rubric::Renderer provides a simple interface for rendering entries, entry sets,
and other things collected by Rubric::WebApp.

=cut

use strict;
use warnings;

use Rubric::Config;
use Template;

=head1 METHODS

=head2 renderer

This method returns an object that renders templates.  By default, it returns a
Template object configured with data from Rubric::Config.  Each type's renderer
is a singleton.

=cut

my %renderer;

sub register_type {
	my ($class, $type, $arg) = @_;
	$renderer{$type} = $arg;
	$renderer{$type}{renderer} = Template->new({
		PROCESS => ("template.$arg->{extension}"),
		INCLUDE_PATH => Rubric::Config->template_path()
	});
}

__PACKAGE__->register_type(@$_) for (
	[ html => { content_type => 'text/html',           extension => 'html' } ],
	[ rss  => { content_type => 'application/rss+xml', extension => 'rss'  } ],
	[ txt  => { content_type => 'text/plain',          extension => 'txt'  } ],
);

sub process { 
	my ($class, $template, $type, $stash) = @_;
	return unless $renderer{$type};

	$template .= '.' . $renderer{$type}{extension};
	$renderer{$type}{renderer}->process($template, $stash, \(my $output));
	return wantarray
		? ($renderer{$type}{content_type}, $output)
		:  $output;
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
