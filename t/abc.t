use Test::More;

use Data::Dumper;

local $Data::Dumper::Sortkeys = 1;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;


my %hash1  = (a  => 1, b  => 2, c => 3);
my %hash2  = (aa => 1, bb => 2, c => 3);

my %A = (c => 3);
my %B = (a  => 1, b  => 2);
my %C = (aa => 1, bb => 2);

my $expected = {
    a => \%A,
    b => \%B,
    c => \%C,
};

#diag Data::Dumper::Dumper $expected;


my $pp_got = Biodiverse::Utils::PP::get_hash_abc (\%hash1, \%hash2);

is_deeply ($pp_got, $expected, 'PP ABC works');

#my $xs_got = {};
my $xs_got = Biodiverse::Utils::XS::get_hash_abc (\%hash1, \%hash2);

#diag Data::Dumper::Dumper $pp_got;

is_deeply ($xs_got, $expected, 'XS ABC works');

#is_deeply ($xs-got->{a}, $expected->{a}, 'a');

done_testing();

