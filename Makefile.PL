use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Rubric',
	AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
	VERSION_FROM        => 'lib/Rubric/WebApp.pm',
	#ABSTRACT_FROM       => 'lib/Rubric/WebApp.pm',
	PL_FILES            => {},
	PREREQ_PM => {
		'CGI::Application' => 3.00,
		'Class::DBI'       => 0.96,
		'Config::Auto'     => 0.11,
		'DBD::SQLite'      => 1.07,
		'Digest::MD5'      => 0.00,
		'Template'         => 2.00,
		'Time::Piece'      => 0.00,
		'YAML'             => 0.00,
		'Class::DBI::AbstractSearch' => 0
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Rubric-*' },
);
