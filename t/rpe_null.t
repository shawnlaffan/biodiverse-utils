use Test::More;

use Biodiverse::Utils::XS;
use Biodiverse::Utils::PP;


my %node_lens     = (a => 1, b => 2, c => 3);
my %local_ranges  = (a => 1, b => 2, c => 3);
my %global_ranges = (a => 1, b => 2, c => 3);


my $null_pp = Biodiverse::Utils::PP::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_pp, 6, 'PP::get_rpe_null works');

my $null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 6, 'XS::get_rpe_null works');


delete $local_ranges{a};
$null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 5, 'XS::get_rpe_null works when missing a key in local ranges');

$local_ranges{a} = 1;
delete $node_lens{a};
$null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 5, 'XS::get_rpe_null works when missing a key in node lens');

$global_ranges{a} = undef;
$null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 5, 'XS::get_rpe_null works when a key in global ranges is null');

$global_ranges{a} = 'barry the wonderdog';
$null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 5, 'XS::get_rpe_null works when a key in global ranges is text');

delete $global_ranges{a};
$null_xs = Biodiverse::Utils::XS::get_rpe_null (\%node_lens, \%local_ranges, \%global_ranges);
is ($null_xs, 5, 'XS::get_rpe_null works when a key in global ranges missing');


done_testing();

