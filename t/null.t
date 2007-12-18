use strict;
use Test::More tests => 3;
use re::engine::POSIX;

=head1 DESCRIPTION

Test C<\0> in strings and patterns

=cut

ok "foo\1bar" !~ /^foo$/ => '\\1 in str';
ok "foo\0bar" =~ /^foo$/ => '\\0 in str';

my $str = "foo\0bar";
ok "foozar" =~ /$str/ => '\\0 cuts off regex';




