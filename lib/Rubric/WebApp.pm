package Rubric::WebApp;

=head1 NAME

Rubric::WebApp - the web interface to Rubric

=head1 VERSION

version 0.00_03

 $Id: WebApp.pm,v 1.8 2004/11/16 16:10:47 rjbs Exp $

=cut

our $VERSION = '0.00_03';

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

	$self->template('login.html');
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

sub this_page {
	my ($self, $iterator) = @_;

	my $first = $self->param('per_page') * ($self->param('page') - 1);
	my $last  = ($self->param('per_page') * $self->param('page')) - 1;
	return $iterator->slice($first, $last);
}

sub recent {
	my ($self) = @_;

	my $entries = 
		Rubric::Entry->retrieve_all;
		
	my $slice = $self->this_page($entries);

	my $pages = int($entries->count / $self->param('per_page'));
	   $pages++ if  $entries->count % $self->param('per_page');

	$self->template('entries.html' => {
		count   => $entries->count,
		entries => $slice,
		pages   => $pages
	});
}

sub display_entries {
	my ($self) = @_;

	my %search = ( user => $self->param('user'), tags => $self->param('tags') );
	my $entries = 
		Rubric::Entry->by_tag(\%search);

	my $slice = $self->this_page($entries);

	my $pages = int($entries->count / $self->param('per_page'));
	   $pages++ if  $entries->count % $self->param('per_page');

	$self->template('entries.html' => {
			%search,
			count   => $entries->count,
			entries => $slice,
			pages   => $pages
	});
}

sub must_login {
	my ($self) = @_;
	$self->template('must_login.html');
}

sub post {
	my ($self) = @_;

	return $self->must_login unless $self->param('current_user');	

	my %entry = (
		uri   => scalar $self->query->param('uri'),
		title => scalar $self->query->param('title'),
		description => scalar $self->query->param('description'),
		tags  => scalar $self->query->param('tags')
	);

	return $self->post_form(\%entry) unless
		(($self->query->param('submit') || '') eq 'save')
		and $entry{uri} and $entry{title};

	use URI;
	$entry{uri} = URI->new($entry{uri})->canonical;

	my $link = Rubric::Link->find_or_create({ uri => $entry{uri} });

	my $entry = Rubric::Entry->find_or_create({
		link => $link,
		user => $self->param('current_user')
	});

	$entry->title($entry{title});
	$entry->description($entry{description});

	$entry->update;
	
	$entry->set_new_tags(grep /\w+/, split /\s+/, $entry{tags});

	$self->display_entries;
}

sub post_form {
	my ($self, $entry) = @_;

	$self->template( 'post.html' => {
		user => $self->param('current_user'),
		form => $entry
	});
}

1;
