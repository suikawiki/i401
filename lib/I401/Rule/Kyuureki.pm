package I401::Rule::Kyuureki;
use strict;
use warnings;
use utf8;
use Kyuureki;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(?:([0-9]+)-([0-9]+)-([0-9]+)|)\s*旧暦},
    code => sub {
      my ($irc, $args) = @_;
      my $now = [gmtime];
      my ($yy, $mm, $dd) = ($1 || $now->[5]+1900, $2 || $now->[4]+1, $3 || $now->[3]);
      my ($y, $m, $lm, $d) = gregorian_to_kyuureki $yy, $mm, $dd;
      my $msg = sprintf '%04d-%02d-%02d は旧暦 %04d/%s%02d/%02d',
          $yy, $mm, $dd, $y || 0, $lm ? '閏' : '', $m || 0, $d || 0;
      $irc->send_notice ($args->{channel}, $msg);
    },
  }, {
    privmsg => 1,
    pattern => qr{(?:([0-9]+)-([0-9]+)-([0-9]+)|)\s*六曜},
    code => sub {
      my ($irc, $args) = @_;
      my $now = [gmtime];
      my ($yy, $mm, $dd) = ($1 || $now->[5]+1900, $2 || $now->[4]+1, $3 || $now->[3]);
      my ($y, $m, $lm, $d) = gregorian_to_kyuureki $yy, $mm, $dd;
      my $msg = sprintf '%04d-%02d-%02d は%s',
          $yy, $mm, $dd, qw(大安 赤口 先勝 友引 先負 仏滅)[($m + $d) % 6];
      $irc->send_notice ($args->{channel}, $msg);
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
