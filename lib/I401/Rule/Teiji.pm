package I401::Rule::Teiji;
use strict;
use warnings;
use utf8;
use Time::Local qw(timegm_nocheck);
use AnyEvent;
use I401::Data::RemoteJSON;

my $Events = {};

sub add_event ($$%) {
  my ($class, $name, %args) = @_;
  $Events->{$name} = \%args;
} # add_event

sub load_leap_data ($) {
  my $code = $_[0];
  I401::Data::RemoteJSON->get (q<https://raw.githubusercontent.com/manakai/data-locale/master/data/datetime/seconds.json>, sub {
    my $data = shift;
    if (ref $data eq 'HASH' and
        ref $data->{positive_leap_seconds} eq 'HASH') {
      my $time;
      my $now = time;
      for (values %{$data->{positive_leap_seconds}}) {
        next unless ref $_ eq 'HASH';
        $time ||= $_->{next_unix} if $_->{next_unix} > $now;
      }
      if (defined $time) {
        __PACKAGE__->add_event (閏秒 => unix => $time);
        __PACKAGE__->add_event (うるう秒 => unix => $time);
      }
    }
    $code->();
  }, max_age => 60*60*24*10);
} # load_leap_data

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
      my $cv = AE::cv;
      if ($name eq '閏秒' or $name eq 'うるう秒') {
        load_leap_data (sub { $cv->send });
      } else {
        $cv->send;
      }
      $cv->cb (sub {
        for (keys %$Events) {
          if ($name =~ /\Q$_\E\z/) {
            $def = $Events->{$_};
            last;
          }
        }
        return unless defined $def;

        my @time = defined $def->{unix} ? gmtime $def->{unix} : gmtime;
        my $step = $def->{step} || 'day';
        if (not defined $def->{unix}) {
          $time[0] = $def->{second} || 0;
          $time[1] = $def->{minute} if defined $def->{minute};
          $time[2] = $def->{hour} if defined $def->{hour};
          $time[3] = $def->{day} if defined $def->{day};
          $time[4] = $def->{month}-1 if defined $def->{month};
          $time[5] = $def->{year} if defined $def->{year};
        }
        my $time = timegm_nocheck (@time);
        if (not defined $def->{unix}) {
          while ($time < time) {
            $time[3]++ if $step eq 'day';
            $time[4]++ if $step eq 'month';
            $time[5]++ if $step eq 'year';
            $time = timegm_nocheck (@time);
          }
        }

        if ($step eq 'year' or defined $def->{unix}) {
          for (1..32, 50, 100, 200, 300) {
            schedule $irc, $args->{channel}, "$name\まであと $_ 日", $time - $_*60*60*24;
          }
          for (1..5, 9, 10, 12, 20, 30, 50, 100) {
            schedule $irc, $args->{channel}, "$name\まであと $_ 時間くらい", $time - $_*60*60;
          }
          for (1, 5, 10, 15, 20, 25, 30, 45, 100) {
            schedule $irc, $args->{channel}, "$name\まであと $_ 分くらい", $time - $_*60;
          }
          for (1..10, 15, 30, 25, 40, 45, 50, 55, 100) {
            schedule $irc, $args->{channel}, "$name\まであと $_ 秒くらい", $time - $_;
          }
        }
        schedule $irc, $args->{channel}, "$name\なう", $time;

        my $seconds = $time - time;
        $irc->send_notice($args->{channel}, "$name\まであと $seconds 秒くらい");
      });
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
