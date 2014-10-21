use strict;
use warnings;
package Rubric::Entry::Formatter::HTMLEscape;
{
  $Rubric::Entry::Formatter::HTMLEscape::VERSION = '0.151';
}
# ABSTRACT: format into HTML by escaping entities


use Template::Filters;


my ($filter, $html, $para);
{
  my $filters = Template::Filters->new;
  $html = $filters->fetch('html');
  $para = $filters->fetch('html_para');

  $filter = sub {
    $para->( $html->($_[0]) );
  }
}

sub as_html {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $filter->($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $html->($arg->{text});
}

1;

__END__
=pod

=head1 NAME

Rubric::Entry::Formatter::HTMLEscape - format into HTML by escaping entities

=head1 VERSION

version 0.151

=head1 DESCRIPTION

This formatter only handles formatting to HTML, and outputs the original
content with HTML-unsafe characters escaped and paragraphs broken.

This is equivalent to filtering with Template::Filters' C<html> and
C<html_para> filters.

=head1 METHODS

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

