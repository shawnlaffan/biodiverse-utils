use Test::More;

use Data::Dumper;

local $Data::Dumper::Sortkeys = 1;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;

my $hash = {
    PARAMS => {
        blort => 1,
        fnort => [1..20],
        snart => undef,
    }
};
my $self = bless $hash, 'Some::Package';

my $got;

$got = Biodiverse::Utils::XS::get_param ($self, 'blort');
is ($got, 1, 'XS get_param works for blort');

$got = Biodiverse::Utils::XS::get_param ($self, 'fnort');
is_deeply ($got, [1..20], 'XS get_param works for fnort');

$got = Biodiverse::Utils::XS::get_param ($self, 'snart');
is ($got, undef, 'XS got undef when expected');

$got = Biodiverse::Utils::XS::get_param ($self, 'snergellyhose');
is ($got, undef, 'XS got undef when param does not exist');


$got = Biodiverse::Utils::PP::get_param ($self, 'blort');
is ($got, 1, 'PP get_param works for blort');

$got = Biodiverse::Utils::PP::get_param ($self, 'fnort');
is_deeply ($got, [1..20], 'PP get_param works for fnort');

$got = Biodiverse::Utils::PP::get_param ($self, 'snart');
is ($got, undef, 'PP got undef when expected');

$got = Biodiverse::Utils::PP::get_param ($self, 'snergellyhose');
is ($got, undef, 'PP got undef when param does not exist');


done_testing();

