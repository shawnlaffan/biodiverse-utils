use strict;
use warnings;
use Benchmark qw /:all/;

use Biodiverse::Utils::PP;
use Biodiverse::Utils::XS;


my @keys = ('a' .. 'zz');
my (%node_lens, %local_ranges, %global_ranges);

@node_lens{@keys} = (1 .. scalar @keys);
@local_ranges{@keys} = (10 .. scalar @keys+10);
@global_ranges{@keys} = (100 .. scalar @keys+100);



cmpthese (
    -5,
    {
        pp => sub {pp()},
        xs => sub {xs()},
    }
);


sub pp {
    my $rpe_null = Biodiverse::Utils::PP::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
}

sub xs {
    my $rpe_null = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
}

__END__

This is perl 5, version 20, subversion 3 (v5.20.3) built for MSWin32-x64-multi-thread

     Rate   pp   xs
pp 4316/s   -- -52%
xs 8960/s 108%   --

     Rate   pp   xs
pp 4506/s   -- -50%
xs 9007/s 100%   --

     Rate   pp   xs
pp 4535/s   -- -50%
xs 9055/s 100%   --
