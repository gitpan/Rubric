#!perl -T
use Test::More tests => 2;
use File::Path qw(mkpath);

use_ok('Rubric::DBI::Setup');

unlink("t/db/rubric.db") if -e "t/db/rubric.db";
mkpath("t/db") unless -d "t/db/";

eval { Rubric::DBI::Setup->setup_tables };

ok(not($@), "set up empty rubric testing db");
