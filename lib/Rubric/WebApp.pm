package Rubric::WebApp;

=head1 NAME

Rubric::WebApp - the web interface to Rubric

=head1 VERSION

version 0.00_13

 $Id: WebApp.pm,v 1.30 2004/12/02 13:56:55 rjbs Exp $

=cut

our $VERSION = '0.00_13';

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Rubric::WebApp;
 Rubric::WebApp->new->run();

It's a CGI::Application!

=head1 DESCRIPTION

Rubric::WebApp provides a CGI-based interface to Rubric data.  It's built on
top of CGI::Application, which does most of the boring work.  This module's
code sets up the dispatch tables and implements the responses to various
queries.

=head1 REQUESTS DISPATCH

Requests are I<mostly> path-based, though some involve form submission.  The
basic dispatch table looks something like this:

 request      | description                               | method called
 -------------+-------------------------------------------+--------------
 /login       | log in to a user account                  | login
 /logout      | log out                                   | logout
 /post        | post or edit an entry (must be logged in) | post
 /edit        | edit an entry (must be logged in)         | edit
 /delete      | delete an entry (must be logged in)       | delete_entry
 /recent      | see recent entries (the default)          | recent
 /user/NAME   | see a user's entries                      | user
 /user/N/TAGS | see a user's entries for given tags       | user
 /tag/TAGS    | see entries for given tags                | tag

=cut

use base qw(CGI::Application);
use CGI::Application::Session;

use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Rubric::Config;
use Rubric::Entry;
use Rubric::Link;
use Rubric::Renderer;
use Rubric::User;

use Template;
use URI; 

=head1 METHODS

=head2 redirect($uri, $message)

This method simplifies redirection; it redirects to the given URI, printing the
given message as the body of the HTTP response.

=cut

sub redirect {
	my ($self, $uri, $message) = @_;

	$self->header_type('redirect');
	$self->header_props(-url=> $uri);
	return $message;
}

=head2 cgiapp_init

This method is called during CGI::Application's initialization.  It finds (or
creates) a CGI::Session, checks for a login, checks for updates to result-set
paging, and starts processing the request path. 

=cut

sub cgiapp_init {
	my ($self) = @_;

	$self->session_config(COOKIE_PARAMS => { -expires => '+3d' });
	$self->check_for_login;
	$self->get_current_user;
	$self->check_pager_data;

	my @path = split '/', $self->query->path_info;
	shift @path for (1 .. 2);
	$self->param(path => \@path);
}

=head2 check_for_login

This method is called by C<cgiapp_init>, and checks for a login attempt in the
submitted request.  A login request is made with two CGI parameters:

 user     - the user's username
 password - the user's password

If these match, the user is now logged in.  If not, it is ignored.

=cut

sub check_for_login {
	my ($self) = @_;

	return unless my $userid = $self->query->param('user');
	return unless my $login_user = Rubric::User->retrieve($userid);

	my $login_pass = $self->query->param('password');
	if (md5_hex($login_pass) eq $login_user->password) {
		$self->session->param('current_user',$self->query->param('user'));
	}
}

=head2 get_current_user

This method is called by C<cgiapp_init>, and retrieves the Rubric::User object
for the currently logged-in user, if any.

=cut

sub get_current_user {
	my ($self) = @_;

	return unless my $userid = $self->session->param('current_user');
	$self->param(current_user => Rubric::User->retrieve($userid));
}

=head2 check_pager_data

This method is called by C<cgiapp_init>, and sets up parameters used for paging
entry listings.  The following parameters are used:

 per_page - how many items per page; default 25, maximum 100; stored in session;
 page     - which page to display; default 1

=cut

sub check_pager_data {
	my ($self) = @_;

	$self->session->param('per_page', int(
		$self->query->param('per_page') || $self->session->param('per_page') || 25
	));
 
	$self->session->param('per_page', 100)
 		if $self->session->param('per_page') > 100;

	$self->param('per_page', $self->session->param('per_page'));
	$self->param('page',     int(($self->query->param('page') || 1)));
}

=head2 template($template, \%variables)

This method is used to render a template with both provided and default
variables.

Templates are rendered by calling the C<process> method on the template
renderer, which is retrieved by calling the C<renderer> method on the WebApp.

The following variables are passed by default:

 current_user - the currently logged-in user (a Rubric::User object)
 per_page     - entries per page (see check_pager_data)
 page         - which page (see check_pager_data)

=cut

sub template {
	my ($self, $template, $stash) = @_;
	$stash ||= {};
	$stash->{current_user} = $self->param('current_user');
	$stash->{per_page} = $self->param('per_page');
	$stash->{page} = $self->param('page');

	my $type = $self->query->param('format') || 'html';
	$type = 'html' unless $type =~ /^\w+$/;
	$template .= ".$type";

	Rubric::Renderer->renderer($type)->process($template, $stash, \(my $output));

	$self->header_props(-type => 'text/rss') if $type eq 'rss';
	return $output;
}

=head2 setup

This method, called by CGI::Application's initialization process, sets up
the dispatch table for requests, as described above.

=cut

sub setup {
	my ($self) = @_;

	$self->mode_param(path_info => 1);
	$self->start_mode('recent');
	
	$self->run_modes([qw[edit entry login logout post recent user tag]]);
	$self->run_modes(delete => 'delete_entry');
}

=head2 entry

This displays the single requested entry.

=cut

sub entry {
	my ($self) = @_;

	unless ($self->get_entry) {
		return $self->redirect( Rubric::Config->uri_root, "No such entry..." );
	}
	$self->template('entry_long' => {
		entry => $self->param('entry'),
		long_form => 1
	});
}

sub get_entry {
	my ($self) = @_;

	my $entryid = shift @{$self->param('path')};
	if ($entryid =~ /^\d+$/) {
		return $self->param(entry => Rubric::Entry->retrieve($entryid));
	}
	return;
}

=head2 login

If the user is logged in, this request is immediately redirected to the root of
the Rubric site.  Otherwise, a login form is provided.

=cut

sub login {
	my ($self) = @_;
	if ($self->param('current_user')) {
		return $self->redirect( Rubric::Config->uri_root, "Logged in..." );
	}
	$self->template('login' => {
		user => scalar $self->query->param('user')
	});
}

=head2 logout

This run mode unsets the "current_user" parameter in the session and the WebApp
object, then redirects the user to the root of the Rubric site.

=cut

sub logout {
	my ($self) = @_;
	$self->session->param('current_user', undef);
	$self->param('current_user', undef);

	return $self->redirect( Rubric::Config->uri_root, "Logged out..." );
}

=head2 user

This method will find the user requested (the name after "/user/" in the path)
and note it in the request.  The request is then redispatched to the C<tag>
method.

=cut

sub user {
	my ($self) = @_;

	my $username = shift @{$self->param('path')};
	if ($username =~ /^\w+$/) {
		$self->param(user => Rubric::User->retrieve($username));
	}

	$self->tag;
}

=head2 tag

This method notes the requested tags (the words after /tag or /user/NAME in the
path) and redispatches to C<display_entries>.

=cut

sub tag {
	my ($self) = @_;

	my $tags = shift @{$self->param('path')};

	$self->param(tags => [ split /\+/, ($tags || '') ]);

	$self->display_entries;
}

=head2 recent

This method uses C<page_entries> and C<render_entries> to display the most
recent entries for all users and tags.

This should probably be what happens when C<display_entries> is called with no
search criteria in place.

=cut

sub recent {
	my ($self) = @_;

	$self->param('recent_tags', Rubric::Entry->recent_tags_counted);
	$self->display_entries;
}

=head2 display_entries

This method searches (with Rubric::Entry) for entries matching the requested
user and tags.  It pages the result (with C<page_entries>) and renders the
resulting page with C<render_entries>.

=cut

sub display_entries {
	my ($self) = @_;

	my %search  = (
		user => $self->param('user'),
		tags => $self->param('tags'),
		link => scalar $self->query->param('link'),
		body => scalar $self->query->param('body'),
	);

	my $entries = Rubric::Entry->by_tag(\%search);

	$self->page_entries($entries)->render_entries;
}

=head2 page_entries($iterator)

Given a Class::DBI::Iterator, this method sets up parameters describing the
current page.  Most importantly, it retrieves an Iterator for the slice of
entries representing the current page.  The following parameters are set:

 entries - a Class::DBI::Iterator for the current page's entries
 count   - the number of entries in the entire set
 pages   - the number of pages the set spans

=cut

sub page_entries {
	my ($self, $iterator) = @_;

	my $first = $self->param('per_page') * ($self->param('page') - 1);
	my $last  = ($self->param('per_page') * $self->param('page')) - 1;
	my $slice = $iterator->slice($first, $last);
	$self->param('entries', $slice);
	$self->param('count', $iterator->count);

	my $pagecount = int($iterator->count / $self->param('per_page'));
	   $pagecount++ if  $iterator->count % $self->param('per_page');
	$self->param('pages', $pagecount);

	return $self;
}

=head2 render_entries

This method renders a template to display the set of entries set up by
C<page_entries>.

=cut

sub render_entries {
	my ($self) = @_;

	$self->template('entries' => {
		user    => $self->param('user'),
		tags    => $self->param('tags'),
		count   => $self->param('count'),
		entries => $self->param('entries'),
		pages   => $self->param('pages'),
		remove  => sub { [ grep { $_ ne $_[0] } @{$_[1]} ] },
		long_form   => scalar $self->query->param('long_form'),
		recent_tags => $self->param('recent_tags'),
	});
}

=head2 edit

If the user isn't logged in, it redirects to demand a login.  If he is, it
displays a post form, completed with the given entry's data.

=cut

sub edit {
	my ($self) = @_;

	return $self->redirect(Rubric::Config->uri_root, "...huh?")
		unless $self->get_entry
		and $self->param('entry')->user eq $self->param('current_user');

	$self->param('existing_entry', $self->param('entry'));
	return $self->post_form();
}

=head2 post

This method wants to be simplified.

If the user isn't logged in, it redirects to demand a login.  If he is, it
checks whether it can create a new entry.  If so, it tries to.  If not, it
displays a form for doing so.  If the user already has an entry for the given
URI, the existing entry is passed to the form renderer.

If a new entry is created, the user is redirected to his entry listing.

=cut

sub post {
	my ($self) = @_;

	return $self->must_login unless my $user = $self->param('current_user');	

	my %entry;
	$entry{$_} = $self->query->param($_)
		for qw(entryid uri title description tags body);
	eval { $entry{uri} = URI->new($entry{uri})->canonical->as_string; };

	if ($entry{uri}) {
		if (my ($link) = Rubric::Link->search({uri => $entry{uri}})) {
			if (my ($existing_entry) = Rubric::Entry->search({link => $link, user => $user})) {
				$self->param('existing_entry', $existing_entry);
			}
		}
	}
	
	return $self->post_form(\%entry) unless
		(($self->query->param('submit') || '') eq 'save')
		and	
		$self->param('current_user')->quick_entry(\%entry);

	my $goto_uri = ($self->query->param('when_done') eq 'go_back')
		? $entry{uri}
		: Rubric::Config->uri_root() . "/user/" . $self->param('current_user');
	
	return $self->redirect( $goto_uri, "Posted..." );
}

=head2 post_form

This method renders a form for the user to create a new entry.

=cut

sub post_form {
	my ($self, $entry) = @_;

	$self->template( 'post' => {
		form           => $entry,
		user           => scalar $self->param('current_user'),
		existing_entry => scalar $self->param('existing_entry'),
		when_done      => scalar $self->query->param('when_done')
	});
}

=head2 must_login

This method renders a form for the user to create a new entry.

=cut

sub must_login {
	my ($self) = @_;
	$self->template('must_login');
}

=head2 delete_entry

This method wants to be simplified.  It's largely copied from C<post>.

If the user isn't logged in, it redirects to demand a login.  If he is, it
checks whether the user has an entry for the given URI.  If so, it's deleted.

Either way, the user is redirected to his entry listing.

=cut

sub delete_entry {
	my ($self) = @_;

	return $self->must_login unless my $user = $self->param('current_user');	

	return $self->redirect( Rubric::Config->uri_root, "No such entry..." )
		unless $self->get_entry;

	return $self->redirect( Rubric::Config->uri_root, "Not your entry..." )
		unless $self->param('entry')->user eq $self->param('current_user');

	$self->param('entry')->delete;

	my $goto_uri = 
		Rubric::Config->uri_root() . "/user/" . $self->param('current_user');

	return $self->redirect( $goto_uri, "Deleted..." );
}

=head1 TODO

=over 4

=item * Entries without links.

=item * Automated new user registration.

=item * Large-body documents on entries.

=back

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
