package I401::Rule::Countries;
use strict;
use warnings;
use utf8;
use I401::Data::RemoteJSON;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{ラッキー国},
    code => sub {
      my ($irc, $args) = @_;
      I401::Data::RemoteJSON->get (q<http://geocol.github.io/data/geocol/data-countries/countries.json>, sub {
        my $data = shift;
        my @region = keys %{$data->{areas}};
        my $region = $region[rand @region];
        my $region_data = $data->{areas}->{$region};
        my $msg = sprintf 'ラッキー国は%s (%s)',
            $region_data->{ja_name} // $region_data->{en_name},
            $region_data->{code} // $region_data->{code3} // '#' . $region;
        $irc->send_notice($args->{channel}, $msg) unless $@;
      });
    },
  });
}

1;
