package re::engine::POSIX;
use 5.009005;
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN
{
    $VERSION = '0.03';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub import
{
    $^H{regcomp} = ENGINE;
}

sub unimport
{
    delete $^H{regcomp}
        if $^H{regcomp} == ENGINE;
}

1;

__END__

=head1 NAME

re::engine::POSIX - POSIX (IEEE Std 1003.1-2001) regular expressions

=head1 SYNOPSIS

    use re::engine::POSIX;

    if ("mooh!" =~ /\([mo]*\)/) {
        say $1; # "moo"
    }

=head1 DESCRIPTION

Replaces perl's regexes in a given lexical scope with the system's
POSIX regular expression engine.

=head1 Modifiers

POSIX regexes (unlike Perl's) behave as if the C<//s> modifier were on
by default, this can be turned off by specifying the B<REG_NEWLINE>
flag to B<regcomp> via C<//m>.

The other valid flags are C<x> and C<i> which turn on B<REG_EXTENDED>
and B<REG_ICASE> respectively.

It is not possible to specify the B<REG_NOTBOL> and B<REG_NOTEOL>
flags as they do not fit within the Perl syntax.

=head1 DIAGNOSTICS

Error messages from from B<regerror> will be propagated on invalid
patterns.

=head1 CAVEATS

Does not ship with its own regexp implementation so it'll fail on
non-POSIX systems.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

Copyright 2007 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
