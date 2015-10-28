package Biodiverse::Utils;

use strict;
use warnings;

our $VERSION = '1.01';

eval 'use Biodiverse::Utils::XS;';
if ($@) {
    use Biodiverse::Utils::PP;
}

1;
