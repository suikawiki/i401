package I401::Rule::Stopwatch;
use strict;
use warnings;
use utf8;

# { channel => { name => start_time, ... }, ... }
my $StartTimes = {};

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+)開始$},
    code => sub {
      my ($irc, $args) = @_;
      my $name = $1;
      $name =~ s/\A\s+//;
      $name =~ s/\s+\z//;
      ($StartTimes->{$args->{channel}} ||= {})->{$name} = time;
      $irc->send_notice($args->{channel}, "$name\開始なう");
    },
  }, {
    privmsg => 1,
    pattern => qr{(.+)終了$},
    code => sub {
      my ($irc, $args) = @_;
      my $name = $1;
      $name =~ s/\A\s+//;
      $name =~ s/\s+\z//;
      my $channel_times = ($StartTimes->{$args->{channel}} || {});
      if (defined $channel_times->{$name}) {
        my $time = time - $channel_times->{$name};
        $irc->send_notice($args->{channel}, "$name\開始から $time s でした");
        delete $channel_times->{$name};
      }
    },
  }, {
    privmsg => 1,
    pattern => qr{途中経過(?:教|おし)えて},
    code => sub {
      my ($irc, $args) = @_;
      my $channel_times = ($StartTimes->{$args->{channel}} || {});
      if (keys %$channel_times) {
        my $lapse_msg = join(', ', map {
            sprintf('%s: %s s', $_, time - $channel_times->{$_});
        } keys %$channel_times);
        $irc->send_notice($args->{channel}, $lapse_msg . ' だよ');
      } else {
        $irc->send_notice($args->{channel}, 'なんもないです');
      }
     },
  });
}

1;
