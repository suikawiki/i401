package I401::Rule::HakobeGame;
use strict;
use warnings;
use utf8;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{^([はこべ])っ([!！?？]?)$},
    code => sub {
      my ($irc, $args) = @_;
      my $msg = {は => 'こ', こ => 'べ', べ => 'は'}->{$1};
      $msg .= 'っ';
      $msg .= {'!' => '!', '！' => '!', '?' => '?', '？' => '?'}->{$2} || '';
      $irc->send_notice($args->{channel}, $msg);
    },
  });
} # get

1;
