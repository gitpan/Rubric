use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

my $v = "\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = "any version";
    my $pv = ($^V || $]);
    $v .= "perl: $pv (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('App::Cmd','any version') };
eval { $v .= pmver('App::Cmd::Command','any version') };
eval { $v .= pmver('App::Cmd::Command::commands','any version') };
eval { $v .= pmver('CGI::Application','3') };
eval { $v .= pmver('CGI::Carp','any version') };
eval { $v .= pmver('CGI::Cookie','any version') };
eval { $v .= pmver('Carp','any version') };
eval { $v .= pmver('Class::Accessor','any version') };
eval { $v .= pmver('Class::DBI','0.96') };
eval { $v .= pmver('Class::DBI::AbstractSearch','any version') };
eval { $v .= pmver('Class::DBI::utf8','any version') };
eval { $v .= pmver('Crypt::CBC','any version') };
eval { $v .= pmver('Crypt::Rijndael','any version') };
eval { $v .= pmver('DBD::SQLite','1.08') };
eval { $v .= pmver('DBI','any version') };
eval { $v .= pmver('Date::Span','1.12') };
eval { $v .= pmver('DateTime','any version') };
eval { $v .= pmver('Digest::MD5','any version') };
eval { $v .= pmver('Email::Address','any version') };
eval { $v .= pmver('Email::Send','any version') };
eval { $v .= pmver('Encode','2') };
eval { $v .= pmver('Exporter','any version') };
eval { $v .= pmver('ExtUtils::MakeMaker','6.30') };
eval { $v .= pmver('File::Copy','any version') };
eval { $v .= pmver('File::Path','any version') };
eval { $v .= pmver('File::ShareDir','any version') };
eval { $v .= pmver('File::ShareDir::Install','0.03') };
eval { $v .= pmver('File::Spec','any version') };
eval { $v .= pmver('HTML::CalendarMonth','any version') };
eval { $v .= pmver('HTML::TagCloud','any version') };
eval { $v .= pmver('HTML::Widget::Factory','0.03') };
eval { $v .= pmver('HTTP::Server::Simple','0.08') };
eval { $v .= pmver('HTTP::Server::Simple::CGI','any version') };
eval { $v .= pmver('JSON','2') };
eval { $v .= pmver('LWP::Simple','any version') };
eval { $v .= pmver('MIME::Base64','any version') };
eval { $v .= pmver('Scalar::Util','any version') };
eval { $v .= pmver('String::TagString','any version') };
eval { $v .= pmver('String::Truncate','any version') };
eval { $v .= pmver('Sub::Exporter','any version') };
eval { $v .= pmver('Template','2.00') };
eval { $v .= pmver('Template::Filters','any version') };
eval { $v .= pmver('Template::Plugin::Class','0.12') };
eval { $v .= pmver('Test::File::ShareDir','any version') };
eval { $v .= pmver('Test::HTTP::Server::Simple','0.02') };
eval { $v .= pmver('Test::More','0.96') };
eval { $v .= pmver('Test::WWW::Mechanize','1.04') };
eval { $v .= pmver('Time::Piece','any version') };
eval { $v .= pmver('YAML::XS','any version') };
eval { $v .= pmver('base','any version') };
eval { $v .= pmver('strict','any version') };
eval { $v .= pmver('warnings','any version') };



# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve you problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
