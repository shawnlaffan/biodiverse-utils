use strict;
use warnings;
use Benchmark qw /:all/;

use Biodiverse::Utils::PP;
use Biodiverse::Utils::XS;


my $hash = {
    PARAMS => {
        blort => 1,
        fnort => [1..20],
        snart => undef,
    },
};
my $self = bless $hash, 'Some::Package';


cmpthese (
    -3,
    {
        pp => sub {pp()},
        xs => sub {xs()},
    }
);


sub pp {
    my $pp_param = Biodiverse::Utils::PP::get_param ($self, 'blort');
}

sub xs {
    my $xs_param = Biodiverse::Utils::XS::get_param ($self, 'blort');
}

__END__

This is perl 5, version 24, subversion 0 (v5.24.0) built for MSWin32-x64-multi-thread
        Rate   xs   pp
xs 2279935/s   -- -21%
pp 2896848/s  27%   --


This is perl 5, version 16, subversion 3 (v5.16.3) built for MSWin32-x64-multi-thread
        Rate  xs  pp
xs 2275546/s  -- -1%
pp 2301985/s  1%  --
