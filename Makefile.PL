use 5.008001;
use strict;
use warnings;
use utf8;

use lib 'inc';
use ExtUtils::MakeMaker;
use Inline::Module;

WriteMakefile(
  NAME => 'Biodiverse::Utils',
  VERSION => '1.01',
  ABSTRACT => 'Utilities for Biodiverse, using XS where possible',
  AUTHOR => 'Shawn Laffan <shawnlaffan@gmail.com>',
  LICENSE => 'lgpl3',
  MIN_PERL_VERSION => '5.008001',
  test => { TESTS => 't/*.t' },
  postamble => {
    inline => {
      module => 'Biodiverse::Utils::XS',
      makestub => 1,
      ilsm => 'Inline::C',
    },
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    prereqs => {
      develop => {
        requires => {
          'Inline::C' => '0.68',
          'Inline::Module' => '0.31',
        },
      },
      test => {
        requires => {
          'Math::Random::MT::Auto'    => '0',
          'List::Util' => '0',
          'Test::More' => '0',
        },
        suggests => {
          'Test::LeakTrace'  => '0',
        },
      },
    },
    resources => {
      homepage    => 'https://github.com/shawnlaffan/biodiverse-utils',
      bugtracker  => {
        web    => 'https://github.com/shawnlaffan/biodiverse-utils/issues',
      },
      repository  => {
        url  => 'https://github.com/shawnlaffan/biodiverse-utils.git',
        web  => 'https://github.com/shawnlaffan/biodiverse-utils',
        type => 'git',
      },
    },
    no_index => {
      directory => [
        'inc',
        'lib/Acme',
      ],
    },
  },
  #DESTDIR => $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt',
);