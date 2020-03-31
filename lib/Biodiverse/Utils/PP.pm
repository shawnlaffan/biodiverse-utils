package Biodiverse::Utils::PP;
our $VERSION = '1.07';
use strict; use warnings;

use List::Util qw /min max/;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(
    add_hash_keys
    add_hash_keys_until_exists
    copy_values_from
    get_rpe_null
    get_hash_shared_and_unique
    get_bnok_ratio
    get_bnok_ratio_lgamma
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
sub add_hash_keys_until_exists {
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
    my $null_node_len_hash = $_[0];
    my $node_ranges_local  = $_[1];
    my $node_ranges_global = $_[2];

    my $pe_null;
    
    foreach my $null_node (keys %$node_ranges_global) {
        $pe_null += $null_node_len_hash->{$null_node}
                  * $node_ranges_local->{$null_node}
                  / $node_ranges_global->{$null_node};
    }
    return $pe_null;
}

sub get_hash_shared_and_unique {
    my ($h1, $h2) = @_;
    
    my %A = (%$h1, %$h2);
    my %B = %A;
    my %C = %A;
    
    delete @B{keys %$h2};
    delete @C{keys %$h1};
    delete @A{(keys %B), (keys %C)};

    return {a => \%A, b => \%B, c => \%C};
}

sub get_bnok_ratio {
    my ($n, $m, $p) = @_;

    croak "m > n or n > p or n <= 0"
      if $n <= 0 || $m > $n || $m > $p;

    my $numer = ($p-$m+1);
    my $nmax  = min (($n-$m), $p);
    my $denom = max ($n-$m, $p) + 1;
    my $dmax  = $n;
    
    my $ratio = 1;
    #  divide as we go to avoid numeric overflow
    while ( $numer <= $nmax and $denom <= $dmax ) {
        $ratio *= $numer / $denom;
        $numer++;
        $denom++;
    }
    #  handle any leftovers
    if ($numer <= $nmax) {
        $ratio *= product ($numer .. $nmax);
    }
    elsif ($denom <= $nmax) {
        $ratio /= product ($denom .. $dmax);
    }

    return $ratio;
}

sub get_bnok_ratio_lgamma {
    my ($n, $m, $p, $lgamma) = @_;
    print "$n $m $p\n";
    return scalar exp(($lgamma->[$n-$m] - $lgamma->[$p-$m]) - ($lgamma->[$n] - $lgamma->[$p]));
}