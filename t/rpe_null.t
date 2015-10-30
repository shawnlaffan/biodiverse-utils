use Test::More;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;


my %node_lens     = (a => 1, b => 2, c => 3);
my %local_ranges  = (a => 1, b => 2, c => 3);
my %global_ranges = (a => 1, b => 2, c => 3);


my $null_pp = Biodiverse::Utils::PP::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);

is ($null_pp, 6, 'PP::get_rpe_null works');


done_testing();