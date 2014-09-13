package I401::Rule::Now;
use strict;
use warnings;
use utf8;
use DateTime;

sub format_time ($$$) {
  my ($dt, $tz, $tz_display) = @_;
  $dt->set_time_zone($tz);
  return sprintf '%02d:%02d %s',
      $dt->hour,
      $dt->minute,
      $tz_display;
}

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(?:今|いま)(?:何時|なんじ)},
    code => sub {
      my ($irc, $args) = @_;

      my $now = DateTime->now(time_zone => 'UTC');
      my $msg = sprintf 'いま %04d-%02d-%02d %s (%s) くらいです',
          $now->year, $now->month, $now->day,
          (format_time $now, 'UTC', 'UTC'),
          join ', ',
              (format_time $now, 'America/Los_Angeles' => 'PT'),
              (format_time $now, 'America/New_York' => 'ET'),
              (format_time $now, 'Europe/Berlin' => 'CET'),
              (format_time $now, 'Asia/Tokyo' => 'JST');

      $irc->send_notice($args->{channel}, $msg);
    },
  }, {
    privmsg => 1,
    pattern => qr{何曜日},
    code => sub {
      my ($irc, $args) = @_;
      my $now = [gmtime];
      my $wd = qw(日 月 火 水 木 金 土)[$now->[6]];
      my $msg = sprintf '本日 %04d-%02d-%02d は%s曜日です',
          $now->[5]+1900, $now->[4]+1, $now->[3], $wd;
      $irc->send_notice ($args->{channel}, $msg);
    },
  }, {
    privmsg => 1,
    pattern => qr{いつやる|^いつ..の$},
    code => sub {
      my ($irc, $args) = @_;
      $irc->send_notice($args->{channel}, "今でしょ!");
    },
  });
}

1;
