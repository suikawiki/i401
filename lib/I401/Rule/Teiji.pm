package I401::Rule::Teiji;
use strict;
use warnings;
use utf8;
use Time::Local qw(timegm_nocheck);
use AnyEvent;

my $Events = {};

sub add_event ($$$) {
  my ($class, $name, %args) = @_;
  $Events->{$name} = \%args;
} # add_event

my $Timers = {};

sub schedule ($$$$) {
  my ($irc, $channel, $msg, $time) = @_;
  my $seconds = $time - time;
  return if $seconds <= 0;
  $Timers->{$channel, $msg, $time} = AE::timer $seconds, 0, sub {
    $irc->send_notice ($channel, $msg);
    undef $Timers->{$channel, $msg, $time};
  };
} # schedule

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+)まだ},
    code => sub {
      my ($irc, $args) = @_;

      my $def;
      my $name = $1;
      $name =~ s/\s+\z//;
      for (keys %$Events) {
        if ($name =~ /\Q$_\E\z/) {
          $def = $Events->{$_};
          last;
        }
      }
      return unless defined $def;

      my @time = gmtime;
      $time[0] = $def->{second} if defined $def->{second};
      $time[1] = $def->{minute} if defined $def->{minute};
      $time[2] = $def->{hour} if defined $def->{hour};
      my $time = timegm_nocheck (@time);
      if ($time < time) {
        $time[3]++;
        $time = timegm_nocheck (@time);
      }

      schedule $irc, $args->{channel}, "$name\なう", $time;

      my $seconds = $time - time;
      $irc->send_notice($args->{channel}, "$name\まであと $seconds 秒");
    },
  }, {
    privmsg => 1,
    pattern => qr{((?:([0-9]+)\s*時間\s*)?(?:([0-9]+)\s*分\s*)?(?:([0-9]+)\s*秒)?)間?[待ま]って},
    code => sub {
      my ($irc, $args) = @_;
      my $seconds = ($2 || 0) * 60 * 60 + ($3 || 0) * 60 + ($4 || 0);
      return unless $seconds;
      schedule $irc, $args->{channel}, "$1\待ったお", time + $seconds;
    },
  });
}

1;
