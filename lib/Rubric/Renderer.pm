package Rubric::Renderer;

=head1 NAME

Rubric::Renderer - the rendering interface for Rubric

=head1 VERSION

 $Id: Renderer.pm,v 1.1 2004/11/29 15:25:46 rjbs Exp $

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
Template object configured with data from Rubric::Config.

=cut

my %renderer;

sub renderer { 
	my ($self, $type) = @_;
	return $renderer{$type} if $renderer{$type};

	$renderer{$type} = Template->new({
		PROCESS => ("template.$type"),
		INCLUDE_PATH => Rubric::Config->template_path()
	});
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
