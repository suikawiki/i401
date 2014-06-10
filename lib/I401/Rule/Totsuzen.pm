package I401::Rule::Totsuzen;
use strict;
use warnings;
use utf8;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(突然の「?.+」?)},
    code => sub {
      my ($irc, $args) = @_;
      my $string = $1;
      if ($string =~ /^突然の「(.+)」$/) {
        $string = $1;
      }
      my $length = length $string;
      $length += length $1 while $string =~ /([\x{3000}-\x{FFFF}\x{20000}-\x{2FFFF}]+)/g;
      if ($length % 2) {
        $length++;
        $string .= ' ';
      }
      if ($length % 4) {
        $length += 2;
        $string = " $string ";
      }

      my $s = '＿' . (join '', (('人') x ($length / 4))) . ' ' . (join '', (('人') x ($length / 4))) . '＿' . "\n" .
              '＞ ' . $string . ' ＜' . "\n" .
              '￣' . (join '^', (('Y') x ($length / 2))) . '￣';

      $irc->send_notice ($args->{channel}, $s);
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
