package Rubric::WebApp;

=head1 NAME

Rubric::WebApp - the web interface to Rubric

=head1 VERSION

version 0.02_04

 $Id: WebApp.pm,v 1.68 2005/01/14 04:06:03 rjbs Exp $

=cut

our $VERSION = '0.02_04';

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
 /preferences | view or change account settings           | preferences
 /newuser     | create a new user account                 | newuser
 /verify      | verify a pending user account             | verify
 /link        | view the details of entries for a link    | link
 /post        | post or edit an entry (must be logged in) | post
 /edit        | edit an entry (must be logged in)         | edit
 /delete      | delete an entry (must be logged in)       | delete
 /user/NAME   | see a user's entries                      | user
 /user/N/TAGS | see a user's entries for given tags       | user
 /tag/TAGS    | see entries for given tags                | tag
 /doc/PAGE    | view the named page in the documentation  | doc

If the system is private and no user is logged in, the default action is to
display a login screen.  If the system is public, or a user is logged in, the
default action is to display entries.

=cut

use base qw(CGI::Application);
use CGI::Application::Session;

use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Email::Address;
use Email::Send;

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;

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

=head2 redirect_root($message)

This is shorthand to redirect to the Rubric's root URI.  It calls C<redirect>.

=cut

sub redirect_root {
	my ($self, $message) = @_;

	return $self->redirect(Rubric::Config->uri_root, $message);
}

=head2 cgiapp_init

This method is called during CGI::Application's initialization.  It finds (or
creates) a CGI::Session, checks for a login, checks for updates to result-set
paging, and starts processing the request path. 

=cut

sub cgiapp_init {
	my ($self) = @_;

	$self->session_config( COOKIE_PARAMS => { -expires => '+7d' } );
	
	my $login_class = Rubric::Config->login_class;
	eval "require $login_class";
	$login_class->check_for_login($self);

	$self->check_pager_data;

	my @path = split '/', $self->query->path_info;
	$self->param(path => [ @path[ 2 .. $#path ] ]);
}

sub next_path_part {
	my ($self) = @_;
	my $username = shift @{$self->param('path')};
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

	my $type = $self->query->param('format');
	   $type = 'html' unless $type and $type =~ /^\w+$/;

	my ($content_type, $output) =
		Rubric::Renderer->process($template, $type, $stash);

	$self->header_add(-type => $content_type);
	return $output;
}

=head2 setup

This method, called by CGI::Application's initialization process, sets up
the dispatch table for requests, as described above.

=cut

sub setup {
	my ($self) = @_;

	$self->mode_param(path_info => 1);
	
	$self->start_mode('login');
	$self->run_modes([ qw(doc login newuser verify) ]);

	if ($self->param('current_user') or not Rubric::Config->private_system) {
		$self->start_mode('entries');
		$self->run_modes([
			qw(delete edit entries entry link logout post preferences user tag)
		]);
	}

	$self->run_modes(AUTOLOAD => 'redirect_root');
}

=head2 entries

This passes off responsibility to the class named in the C<entries_query_class>
configuration option.  This option defaults to Rubric::WebApp::EntriesQuery.

=cut

sub entries {
	my ($self) = @_;

	my $entries_class = Rubric::Config->entries_query_class;
	eval "require $entries_class";
	if ($@) { warn $@; return $self->redirect_root; }
	$entries_class->entries($self);
}

=head2 entry

This displays the single requested entry.

=cut

sub entry {
	my ($self) = @_;

	return $self->redirect_root("No such entry...")
		unless ($self->get_entry);

	$self->template('entry_long' => {
		entry => $self->param('entry'),
		long_form => 1
	});
}

=head2 get_entry

This method gets the next part of the path, assumes it to be a Rubric::Entry
id, and puts the corresponding entry in the "entry" parameter.

=cut

sub get_entry {
	my ($self) = @_;

	$self->param(entry => Rubric::Entry->retrieve($self->next_path_part));
	return $self;
}

=head2 link

This runmode displays entries that point to a given link, identified either by
URI or MD5 sum.

=cut

sub link {
	my ($self) = @_;
	return $self->redirect_root("...no such link") unless $self->get_link;
	$self->display_entries;
}

=head2 get_link

This method look for a C<uri> or, failing that, C<url> query parameter.  If
found, it finds a Rubric::Link for that URI and puts it in the "link"
parameter.

=cut

sub get_link {
	my ($self) = @_;
	my %search;
	$search{md5} = $self->query->param('md5');
	$search{uri} = $self->query->param('uri') || $self->query->param('url');
	for (qw(md5sum uri)) {
		delete $search{$_} unless $search{$_};
	}
	return unless %search;
	return unless my ($link) = Rubric::Link->search(\%search);
	$self->param('link', $link);
	return $self;
}

=head2 login

If the user is logged in, this request is immediately redirected to the root of
the Rubric site.  Otherwise, a login form is provided.

=cut

sub login {
	my ($self) = @_;

	return $self->redirect_root("Logged in...")
		if $self->param('current_user');

	$self->template('login' => {
		user => scalar $self->query->param('user'),
		user_pending => scalar $self->param('user_pending')
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

	return $self->redirect_root("Logged out...");
}

=head2 preferences

This method displays account information for the current user.  Some account
settings may be changed.

=cut

sub preferences {
	my ($self) = @_;

	return $self->redirect_root("permission denied")
		unless $self->param('current_user');
	
	return $self->template("preferences")
		unless my %prefs = $self->_get_prefs_form;

	if (my %errors = $self->validate_prefs(\%prefs)) {
		return $self->template("preferences", { %prefs, %errors } );
	}

	$self->update_user(\%prefs);
}

sub update_user {
	my ($self, $prefs) = @_;
	for ($self->param('current_user')) {
		$_->password(md5_hex($prefs->{password_1})) if $prefs->{password_1};
		$_->email($prefs->{email});
		$_->update;
	}
	$self->redirect_root('updated');
}

sub _get_prefs_form {
	my ($self) = @_;

	my %form;
	for (qw(password password_1 password_2 email)) {
		$form{$_} = $self->query->param($_) if $self->query->param($_);
	}
	return %form;
}

sub validate_prefs {
	my ($self, $prefs) = @_;
	my %errors;

	unless ($prefs->{email}) {
		$errors{email_missing} = 1;
	} elsif ($prefs->{email} and $prefs->{email} !~ $Email::Address::addr_spec) {
		undef $prefs->{email};
		$errors{email_invalid} = 1;
	}

	if (
		$prefs->{password_1} and $prefs->{password_2}
		and $prefs->{password_1} ne $prefs->{password_2}
	) {
		undef $prefs->{password_1};
		undef $prefs->{password_2};
		$errors{password_mismatch} = 1;
	}

	unless ($prefs->{password}) {
		$errors{password_missing} = 1;
	} elsif (
		md5_hex($prefs->{password}) ne $self->param('current_user')->password
	) {
		$errors{password_wrong} = 1;
	}

	return %errors;
}

=head2 newuser

If the proper form information is present, this runmode creates a new user
account.  If not, it presents a form.

If a user is already logged in, the user is redirected to the root of the
Rubric.

=cut

sub newuser {
	my ($self) = @_;

	return $self->redirect_root("registration is closed...")
		if Rubric::Config->registration_closed;

	return $self->redirect_root("Already logged in...")
		if $self->param('current_user');
	
	my %newuser;
	$newuser{$_} = $self->query->param($_)
		for qw(username password_1 password_2 email);

	my %errors = $self->validate_newuser_form(\%newuser);
	if (%errors) {
		$self->template('newuser' => { %newuser, %errors });
	} else {
		$self->create_newuser(%newuser);
	}
}

sub validate_newuser_form {
	my ($self, $newuser) = @_;
	my %errors;

	if ($newuser->{username} and $newuser->{username} !~ /^[\w\d.]+$/) {
		undef $newuser->{username};
		$errors{username_invalid} = 1;
	} elsif (Rubric::User->retrieve($newuser->{username})) {
		undef $newuser->{username};
		$errors{username_taken} = 1;
	}
	
	unless ($newuser->{email}) {
		$errors{email_missing} = 1;
	} elsif ($newuser->{email} and $newuser->{email} !~ $Email::Address::addr_spec) {
		undef $newuser->{email};
		$errors{email_invalid} = 1;
	}

	if (
		$newuser->{password_1} and $newuser->{password_2}
		and $newuser->{password_1} ne $newuser->{password_2}
	) {
		undef $newuser->{password_1};
		undef $newuser->{password_2};
		$errors{password_mismatch} = 1;
	}
	return %errors;
}

sub create_newuser {
	my ($self, %newuser) = @_;

	my %user = (
		username => $newuser{username},
		password => md5_hex($newuser{password_1}),
		email    => $newuser{email},
	);

	$user{verification_code} = md5_hex("%user".time)
		unless Rubric::Config->skip_newuser_verification;

	my $user = Rubric::User->create(\%user);

	$self->send_verification_email_to($user)
		unless Rubric::Config->skip_newuser_verification;

	$self->template("account_created");
}

sub send_verification_email_to {
	my ($self, $user) = @_;

	my $message = Rubric::Renderer->process(
		'newuser_mail',
		'txt',
		{ user => $user, email_from => Rubric::Config->email_from }
	);

	send SMTP => $message => Rubric::Config->smtp_server;
}

=head2 verify

This runmode attempts to verify a user account.  It expects a request to be
in the form: C< /verify/username/verification_code >

=cut

sub verify {
	my ($self) = @_;

	return $self->redirect_root("Already logged in...")
		if $self->param('current_user');

	$self->get_user->get_verification_code;

	return $self->redirect_root("no such user")
		if defined $self->param('user') and $self->param('user') eq '';

	return $self->param('user')->verify($self->param('verification_code'))
		? $self->template('verified')
		: $self->redirect_root("BAD USER NO VALIDATION");
}

sub get_verification_code {
	my ($self) = @_;

	$self->param(verification_code => $self->next_path_part);

	return $self;
}

sub user {
	my ($self) = @_;
	$self->get_user->get_tags->display_entries;
}

sub get_user {
	my ($self) = @_;

	$self->param(user => Rubric::User->retrieve($self->next_path_part) || '');

	return $self;
}

=head2 display_entries

This method searches (with Rubric::Entry) for entries matching the requested
user and tags.  It pages the result (with C<page_entries>) and renders the
resulting page with C<render_entries>.

=cut

sub display_entries {
	my ($self) = @_;

	return $self->redirect_root("no such user")
		if defined $self->param('user') and $self->param('user') eq '';

	$self->param('has_body', scalar $self->query->param('has_body'));
	$self->param('has_link', scalar $self->query->param('has_link'));

	my %search = (
		user => $self->param('user'),
		tags => $self->param('tags'),
		link => $self->param('link'),
		has_body => $self->param('has_body'),
		has_link => $self->param('has_link'),
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

	my $first =  $self->param('per_page') * ($self->param('page')  - 1);
	my $last  = ($self->param('per_page') *  $self->param('page')) - 1;
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
	my ($self, $options) = @_;
	$options ||= {};

	$self->template('entries' => {
		count   => $self->param('count'),
		entries => $self->param('entries'),
		pages   => $self->param('pages'),
		%$options,
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

	return $self->redirect_root("...huh?")
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
		: Rubric::WebApp::URI->entries({ user => $self->param('current_user') });
	
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

=head2 delete

This method wants to be simplified.  It's largely copied from C<post>.

If the user isn't logged in, it redirects to demand a login.  If he is, it
checks whether the user has an entry for the given URI.  If so, it's deleted.

Either way, the user is redirected to his entry listing.

=cut

sub delete {
	my ($self) = @_;

	return $self->must_login unless my $user = $self->param('current_user');	

	return $self->redirect_root("No such entry...")
		unless $self->get_entry;

	return $self->redirect_root("Not your entry...")
		unless $self->param('entry')->user eq $self->param('current_user');

	$self->param('entry')->delete;

	return $self->redirect(
		Rubric::WebApp::URI->entries({user=>$self->param('current_user')}),
		"Deleted..."
	);
}

=head2 doc

This runmode returns a mostly-static document from the template path.

=cut

sub doc {
	my ($self) = @_;

	$self->get_doc->template("docs/" . $self->param('doc_page'));
}

=head2 get_doc

This gets the next part of the path and puts it in the C<doc_page> parameter.

=cut

sub get_doc {
	my ($self) = @_;

	my $doc_page = $self->next_path_part;
	$self->param(doc_page => $doc_page) if $doc_page =~ /^\w+$/;

	return $self;
}

=head1 TODO

=over 4

=item * change email, password

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
