package I401::Rule::Anybody;
use strict;
use warnings;
use utf8;

my $BeggingText = [
  'お願いします',
  'よろすく',
  'まかせた',
  '頼む',
  'おにゃーしゃー',
  'じゃあそれで',
];

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{>?\s?(?:誰|だれ)か},
    code    => sub {
      my ($irc, $args) = @_;
      my $users = $irc->get_channel_users($args->{channel});
      my $msg = join(' > ', $BeggingText->[int(rand(@$BeggingText))], $users->[int(rand(@$users))]);
      my $method = $args->{text} =~ />\s?(?:誰|だれ)か/ ? 'send_privmsg' : 'send_notice';
      $irc->$method($args->{channel}, $msg);
    },
  });
}

1;
