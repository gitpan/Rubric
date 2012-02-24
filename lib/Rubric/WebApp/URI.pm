use strict;
use warnings;
package Rubric::WebApp::URI;
{
  $Rubric::WebApp::URI::VERSION = '0.151';
}
# ABSTRACT: URIs for Rubric web requests


use Rubric::Config;
use Scalar::Util ();


sub root { Rubric::Config->uri_root }


sub stylesheet {
  my $href = Rubric::Config->css_href;
  return $href if $href;
  return Rubric::Config->uri_root . '/style/rubric.css';
}


sub logout { Rubric::Config->uri_root . '/logout' }


sub login { Rubric::Config->uri_root . '/login' }


sub reset_password {
	my ($class, $arg) = @_;
	my $uri = Rubric::Config->uri_root . '/reset_password';
	if ($arg->{user} and defined $arg->{reset_code}) {
		$uri .= "/$arg->{user}/$arg->{reset_code}";
	}
	return $uri;
}


sub newuser {
	return if Rubric::Config->registration_closed;
	return Rubric::Config->uri_root . '/newuser';
}


sub entries {
	my ($class, $arg) = @_;
	$arg->{tags} ||= {};
  $arg->{tags} = { map { $_ => undef } @{$arg->{tags}} }
    if ref $arg->{tags} eq 'ARRAY';

	my $format = delete $arg->{format};

	my $uri = $class->root . '/entries';
	$uri .= "/user/$arg->{user}" if $arg->{user};
	$uri .= '/tags/' . join('+', keys %{$arg->{tags}}) if %{$arg->{tags}};
	for (qw(has_body has_link)) {
		$uri .= "/$_/" . ($arg->{$_} ? 1 : 0)
			if (defined $arg->{$_} and $arg->{$_} ne '');
	}
	$uri .= "/urimd5/$arg->{urimd5}" if $arg->{urimd5};
	$uri .= "?format=$format" if $format;
	return $uri;
}


sub entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/entry/" . $entry->id;
}



sub edit_entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/edit/" . $entry->id;
}


sub delete_entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/delete/" . $entry->id;
}


sub post_entry { Rubric::Config->uri_root . "/post"; }


sub by_date {
	my ($class) = @_;
  shift;
  my $year = shift;
  my $month = shift;
  my $uri = '/calendar';
  $uri .= "/$year" if ($year);
  $uri .= "/$month" if ($month);

	Rubric::Config->uri_root . $uri;
}




sub tag_cloud {
	my ($class) = @_;
	Rubric::Config->uri_root . "/tag_cloud";
}



sub preferences { Rubric::Config->uri_root . "/preferences"; }


sub verify_user {
	my ($class, $user) = @_;
	Rubric::Config->uri_root . "/verify/$user/" . $user->verification_code;
}


sub doc {
	my ($class, $doc_page) = @_;
	Rubric::Config->uri_root . "/doc/" . $doc_page;
}

1;

__END__
=pod

=head1 NAME

Rubric::WebApp::URI - URIs for Rubric web requests

=head1 VERSION

version 0.151

=head1 DESCRIPTION

This module provides methods for generating the URIs for Rubric requests.

=head1 METHODS

=head2 root

the URI for the root of the Rubric; taken from uri_root in config

=head2 stylesheet

the URI for the stylesheet

=head2 logout

URI to log out

=head2 login

URI to form for log in

=head2 reset_password

URI to reset user password

=head2 newuser

URI to form for new user registration form;  returns false if registration is
closed.

=head2 entries(\%arg)

URI for entry listing; valid keys for C<%arg>:

 user - entries for one user
 tags - arrayref of tag names

=head2 entry($entry)

URI to view entry

=head2 edit_entry($entry)

URI to edit entry

=head2 delete_entry($entry)

URI to delete entry

=head2 post_entry

URI for new entry form

=head2 by_date

URI for by_date

=head2 tag_cloud

URI for all tags / tag cloud

=head2 preferences

URI for preferences form

=head2 verify_user

URI for new entry form

=head2 doc($doc_page)

URI for documentation page.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

