package I401::Rule::Weather;
use strict;
use warnings;
use utf8;
use I401::Data::RemoteJSON;

## <http://openweathermap.org/current>

my $CityIDs = {
  京都 => 1857910,
  京都市 => 1857910,
  上京区 => 8125829,
  東京 => 1850147,
  品川 => 1852140,
};

my $Weather = {
  Clear => q<晴>,
  Clouds => q<曇>,
  Rain => q<雨>,
  Thunderstorm => q<雷雨>,
};

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+)の天気},
    code => sub {
      my ($irc, $args) = @_;
      my $city = $1;
      my $id = $CityIDs->{$city} or return;
      my $url = q<http://api.openweathermap.org/data/2.5/weather?units=metric&id=> . $id;
      I401::Data::RemoteJSON->get ($url, sub {
        my $data = shift;
        my $msg = eval {
          my $weather = $data->{weather}->[0]->{main};
          my @time = gmtime $data->{dt};
          sprintf '%sの現在の天気は%s、気温 %d°C、湿度 %d%%、気圧 %dhPa (%d/%d %02d:%02d UTC)',
              $city,
              $Weather->{$weather} // $weather,
              $data->{main}->{temp},
              $data->{main}->{humidity},
              $data->{main}->{pressure},
              $time[4]+1, $time[3], $time[2], $time[1];
        };
        warn $@ if $@;
        $irc->send_notice($args->{channel}, $msg) unless $@;
      });
    },
  });
}

1;
