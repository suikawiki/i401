package I401::Rule::Stopwatch;
use strict;
use warnings;
use utf8;

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
      $StartTimes->{$name} = time;
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
      if (defined $StartTimes->{$name}) {
        my $time = time - $StartTimes->{$name};
        $irc->send_notice($args->{channel}, "$name\開始から $time s でした");
      }
    },
  });
}

1;
