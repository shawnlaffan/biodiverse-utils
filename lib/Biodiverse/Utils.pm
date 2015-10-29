package Biodiverse::Utils;

use strict;
use warnings;

our $VERSION = '1.01';

BEGIN {
    eval 'use Biodiverse::Utils::XS qw /:all/;';
    if ($@) {
        use Biodiverse::Utils::PP qw /:all/;
    }
}

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_last_if_exists_exists
    copy_values_from
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

1;
