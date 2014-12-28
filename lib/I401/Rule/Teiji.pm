package I401::Rule::Teiji;
use strict;
use warnings;
use utf8;
use Time::Local qw(timegm_nocheck);
use AnyEvent;

my $Events = {};

sub add_event ($$%) {
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
      $time[0] = $def->{second} || 0;
      $time[1] = $def->{minute} if defined $def->{minute};
      $time[2] = $def->{hour} if defined $def->{hour};
      $time[3] = $def->{day} if defined $def->{day};
      $time[4] = $def->{month}-1 if defined $def->{month};
      $time[5] = $def->{year} if defined $def->{year};
      my $step = $def->{step} || 'day';
      my $time = timegm_nocheck (@time);
      while ($time < time) {
        $time[3]++ if $step eq 'day';
        $time[4]++ if $step eq 'month';
        $time[5]++ if $step eq 'year';
        $time = timegm_nocheck (@time);
      }

      if ($step eq 'year') {
        for (1..32) {
          schedule $irc, $args->{channel}, "$name\まであと $_ 日", $time - $_*60*60*24;
        }
        for (1..5, 10, 12) {
          schedule $irc, $args->{channel}, "$name\まであと $_ 時間くらい", $time - $_*60*60;
        }
        for (1, 5, 10, 30) {
          schedule $irc, $args->{channel}, "$name\まであと $_ 分くらい", $time - $_*60;
        }
        for (1..10, 30) {
          schedule $irc, $args->{channel}, "$name\まであと $_ 秒くらい", $time - $_;
        }
      }
      schedule $irc, $args->{channel}, "$name\なう", $time;

      my $seconds = $time - time;
      $irc->send_notice($args->{channel}, "$name\まであと $seconds 秒くらい");
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
