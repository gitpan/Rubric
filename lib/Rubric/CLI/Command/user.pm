package Rubric::CLI::Command::user;

=head1 NAME

Rubric::CLI::Command::user - Rubric user management commands

=head1 VERSION

 $Id: /my/cs/projects/rubric/trunk/lib/Rubric/CLI/Command/user.pm 18100 2006-01-26T13:59:16.285684Z rjbs  $

=cut

use strict;
use warnings;

use base qw(Rubric::CLI::Command);

use Digest::MD5 qw(md5_hex);
use Rubric::User;

sub describe_options {
  my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(
    "rubric user %o [username]",
    [ "new-user|n",        "add a user (requires --email and --pass)" ],
    [ "activate|a",        "activate an existing user"                ],
    [ "password|pass|p=s", "set user's password"                      ],
    [ "email|e=s",         "set user's email address"                 ],
  );

  die $usage->text unless @ARGV == 1;

  return ($opt, $usage);
}

sub execute {
  my ($class) = @_;

  my ($opt, $usage) = $class->describe_options;

  my $username = $ARGV[0];

  die "--new-user and --activate are mutually exclusive"
    if $opt->{new_user} and $opt->{activate};

  if ($opt->{new_user}) {
    die "--new-user requries --email and --pass"
      unless $opt->{email} and $opt->{pass};

    my $user = Rubric::User->create({
      username => $username,
      password => md5_hex($opt->{pass}),
      email    => $opt->{email},
    });

    die "couldn't create user" unless $user;

    print "created user $user";
    exit;
  }

  my $user = Rubric::User->retrieve($username);

  die "couldn't find user for '$username'" unless $user;

  if ($opt->{activate}) {
    $user->verification_code(undef);
    print "activated user account\n";
  }

  if ($opt->{email}) {
    $user->email($opt->{email});
    print "changed email\n";
  }

  if ($opt->{password}) {
    $user->password(md5_hex($opt->{password}));
    print "changed password\n";
  }

  $user->update;

  print "username: ", $user->username, "\n";
  print "email   : ", $user->email,    "\n";
}

1;
