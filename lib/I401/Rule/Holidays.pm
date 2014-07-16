package I401::Rule::Holidays;
use strict;
use warnings;
use utf8;
use I401::Data::RemoteJSON;
use Time::Local qw(timegm_nocheck);

my $URL = q<https://raw.githubusercontent.com/manakai/data-locale/master/data/calendar/jp-holidays.json>;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{((?:次の)+|(?:前の)+)祝日},
    code => sub {
      my ($irc, $args) = @_;
      my $mod = $1;
      I401::Data::RemoteJSON->get ($URL, sub {
        my $data = shift;
        my $delta = (length $mod) / 2;
        $delta *= -1 if $mod =~ /前の/;
        my @today = gmtime;
        my $today = sprintf '%04d-%02d-%02d',
            $today[5]+1900, $today[4]+1, $today[3];
        $data->{$today} ||= '';
        my @date = sort { $a cmp $b } keys %$data;
        my $today_i;
        for (0..$#date) {
          if ($date[$_] eq $today) {
            $today_i = $_;
            last;
          }
        }
        my $i = $today_i + $delta;
        if (0 <= $i and $i <= $#date) {
          $date[$i] =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})/;
          my $time = [gmtime timegm_nocheck 0, 0, 0, $3, $2-1, $1];
          my $wday = qw(日 月 火 水 木 金 土)[$time->[6]];
          my $msg = sprintf '%s祝日は %s (%s) %s です。',
              $mod, $date[$i], $wday, $data->{$date[$i]};
          $irc->send_notice($args->{channel}, $msg);
        }
      });
    },
  });
}

1;
