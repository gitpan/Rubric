use Rubric::User;
use Digest::MD5 qw(md5_hex);
my ($username, $password) = @ARGV;
Rubric::User->create({ username => $username, password => md5_hex($password) });
