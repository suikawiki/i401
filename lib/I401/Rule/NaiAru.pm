package I401::Rule::NaiAru;
use strict;
use warnings;
use utf8;

my @suffix = ('', qw(
  な
  なぁ
  な!!
  wwwww
  !!!!
  〜〜〜!!!!
));

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(\w+)(?<!て)ない[?？]*$},
    code => sub {
      my ($irc, $args) = @_;
      my $msg = "$1ある";
      $msg .= $suffix[rand @suffix];
      $irc->send_privmsg ($args->{channel}, $msg);
    },
  });
}

1;
