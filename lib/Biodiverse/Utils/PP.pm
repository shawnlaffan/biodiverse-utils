package Biodiverse::Utils::PP;
our $VERSION = '1.01';
use strict; use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_last_if_exists
    copy_values_from
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub add_hash_keys {}  #  stub for now

sub copy_values_from {
    my ($dest, $from) = @_;
    @$dest{keys %$dest} = @$from{keys %$dest};
}

#  Could use Data::Alias for some speedup here,
#  but it's best to use the XS version
sub add_hash_keys_last_if_exists {
    my ($dest, $from) = @_; 
    if (!scalar keys %$dest) {
        @$dest{@$from} = undef;
        
    }
    else {
        foreach my $key (@$from) {
            last if exists $dest->{$key};
            $dest->{$key} = undef;
        }
    }
}

