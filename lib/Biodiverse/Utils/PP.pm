package Biodiverse::Utils::PP;
our $VERSION = '1.01';
use strict; use warnings;

use Data::Alias qw /alias/;

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_last_if_exists
    copy_values_from
    get_rpe_null
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub add_hash_keys {
    my ($dest, $from) = @_;
    @$dest{keys %$from} = undef;
}

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

sub get_rpe_null {
    alias my %null_node_len_hash = %{$_[0]};
    alias my %node_ranges_local  = %{$_[1]};
    alias my %node_ranges_global = %{$_[2]};

    my $pe_null;
    
    foreach my $null_node (keys %node_ranges_global) {
        $pe_null += $null_node_len_hash{$null_node}
                  * $node_ranges_local{$null_node}
                  / $node_ranges_global{$null_node};
    }
    return $pe_null;
}

