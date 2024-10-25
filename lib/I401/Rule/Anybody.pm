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
      my $method = $args->{message}->text =~ />\s?(?:誰|だれ)か/ ? 'send_privmsg' : 'send_notice';
      $irc->$method($args->{channel}, $msg);
    },
  });
}

1;

=head1 LICENSE

Copyright 2014 Hatena <http://www.hatena.ne.jp/company/>.

Copyright 2024 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
