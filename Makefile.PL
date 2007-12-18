use utf8;
use inc::Module::Install;

name 're-engine-POSIX';

perl_version '5.009005';

author 'Ævar Arnfjörð Bjarmason <avar@cpan.org>';

abstract_from 'POSIX.pm';
license_from  'POSIX.pm';

# t/
build_requires 'Test::More' => 0; # 5.007003

tests 't/*.t';

auto_install;
WriteAll;
