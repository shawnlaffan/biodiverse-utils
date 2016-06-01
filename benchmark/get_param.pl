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
    }
};
my $self = bless $hash, 'Some::Package';


cmpthese (
    -5,
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

my @letters = ('a'..'zz');
my @numbers = (0..200);
my $subset = 5;

     Rate   pp   xs
pp  921/s   -- -68%
xs 2898/s 215%   --

###

my @letters = ('a'..'zz');
my @numbers = (0..200);
my $subset = 50;

     Rate   pp   xs
pp  904/s   -- -68%
xs 2822/s 212%   --

###

my @letters = ('a'..'z');
my @numbers = (0..20);
my $subset = 10;

      Rate   pp   xs
pp 18140/s   -- -66%
xs 53918/s 197%   --