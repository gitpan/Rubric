package Rubric::WebApp;

=head1 NAME

Rubric::WebApp - the web interface to Rubric

=head1 VERSION

version 0.00_05

 $Id: WebApp.pm,v 1.13 2004/11/19 03:59:04 rjbs Exp $

=cut

our $VERSION = '0.00_05';

use base qw(CGI::Application);
use CGI::Application::Session;

use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

use Rubric::Config;
use Rubric::Entry;
use Rubric::Link;
use Rubric::User;

use Template;
use URI; 

sub renderer { 
	my ($self) = @_;
	return $self->param('renderer') if $self->param('renderer');

	my $renderer = Template->new({
		INCLUDE_PATH => Rubric::Config->template_path()
	});
	$self->param('renderer', $renderer);
}

sub template {
	my ($self, $template, $stash) = @_;
	$stash ||= {};
	$stash->{current_user} = $self->param('current_user');
	$stash->{per_page} = $self->param('per_page');
	$stash->{page} = $self->param('page');
	$stash->{url_for} = \&url_for;

	my $output;
	$self->renderer->process($template, $stash, \$output);
	return $output;
}

sub url_for {
	my ($what, $user, $tags, $text) = @_;
	my $root = Rubric::Config->url_root;
	if ($what eq 'root') {
		return "<a href='$root'>(root)</a>";
	} elsif ($what eq 'css') {
		return Rubric::Config->css_href;
	} elsif ($what eq 'logout') {
		return "<a href='$root/logout'>logout</a>";
	} elsif ($what eq 'login') {
		return "<a href='$root/login'>login</a>";
	} elsif ($what eq 'entries') {
		if ($user) {
			return "<a href='$root/user/$user/" . join('+',@$tags) . "'>$text</a>";
		} elsif ($tags and @$tags) {
			return "<a href='$root/tag/" . join('+',@$tags) . "'>$text</a>";
		}
		return url_for('root');
	} elsif ($what eq 'post') {
		return "<a href='$root/post/'>new entry</a>";
	}
}

sub check_for_login {
	my ($self) = @_;

	return unless my $userid = $self->query->param('user');
	return unless my $login_user = Rubric::User->retrieve($userid);

	my $login_pass = $self->query->param('password');
	if (md5_hex($login_pass) eq $login_user->password) {
		$self->session->param('current_user',$self->query->param('user'));
	}
}

sub get_current_user {
	my ($self) = @_;

	return unless my $userid = $self->session->param('current_user');
	$self->param(current_user => Rubric::User->retrieve($userid));
}

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

sub cgiapp_init {
	my ($self) = @_;

	$self->check_for_login;
	$self->get_current_user;
	$self->check_pager_data;

	my @path = split '/', $self->query->path_info;
	shift @path for (1 .. 2);
	$self->param(path => \@path);
}

sub setup {
	my ($self) = @_;

	$self->mode_param(path_info => 1);
	$self->start_mode('recent');
	
	$self->run_modes([qw[login logout post recent user tag]]);
}

sub login {
	my ($self) = @_;
	if ($self->param('current_user')) {
		$self->header_type('redirect');
		$self->header_props(-url=> Rubric::Config->url_root);
		return "Logged in...";
	}
	$self->template('login.html' => { user => $self->query->param('user') });
}

sub logout {
	my ($self) = @_;
	$self->session->clear;
	$self->session->delete;
	$self->param('current_user', undef);
	$self->recent;
}

sub user {
	my ($self) = @_;

	my $username = shift @{$self->param('path')};
	if ($username =~ /^\w+$/) {
		$self->param(user => Rubric::User->retrieve($username));
	}

	$self->tag;
}

sub tag {
	my ($self) = @_;

	my $tags = shift @{$self->param('path')};

	$self->param(tags => [ split /\+/, ($tags || '') ]);

	$self->display_entries;
}

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

sub render_entries {
	my ($self) = @_;

	$self->template('entries.html' => {
		user    => $self->param('user'),
		tags    => $self->param('tags'),
		count   => $self->param('count'),
		entries => $self->param('entries'),
		pages   => $self->param('pages'),
		recent_tags => $self->param('recent_tags'),
	});
}

sub recent {
	my ($self) = @_;

	my $entries = Rubric::Entry->retrieve_all;
	$self->param('recent_tags', [ Rubric::Entry->recent_tags_counted ]);
	$self->page_entries($entries)->render_entries;
}

sub display_entries {
	my ($self) = @_;

	my %search  = ( user => $self->param('user'), tags => $self->param('tags') );
	my $entries = Rubric::Entry->by_tag(\%search);

	$self->page_entries($entries)->render_entries;
}

sub must_login {
	my ($self) = @_;
	$self->template('must_login.html');
}

sub post {
	my ($self) = @_;

	return $self->must_login unless my $user = $self->param('current_user');	

	my %entry;
	$entry{$_} = $self->query->param($_)
		for qw(uri title description tags);
	eval { $entry{uri} = URI->new($entry{uri})->canonical->as_string; };

	if (my ($link) = Rubric::Link->search({uri => $entry{uri}})) {
		if (my ($existing_entry) = Rubric::Entry->search({link => $link, user => $user})) {
			$self->param('existing_entry', $existing_entry);
		}
	}
	
	unless (
		(($self->query->param('submit') || '') eq 'save')
		and
		$self->param('current_user')->quick_entry(\%entry)
	) {
		return $self->post_form(\%entry)
	}

	my $goto_url = $self->query->param('go_back')
		? $entry{uri}
		: Rubric::Config->url_root() . "/user/" . $self->param('current_user');

	$self->header_type('redirect');
	$self->header_props( -url => $goto_url);
	return "Posted...";
}

sub post_form {
	my ($self, $entry) = @_;

	$self->template( 'post.html' => {
		form           => $entry,
		user           => scalar $self->param('current_user'),
		existing_entry => scalar $self->param('existing_entry'),
	});
}

1;
