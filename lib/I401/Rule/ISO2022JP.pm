package I401::Rule::ISO2022JP;
use strict;
use warnings;
use utf8;
use Encode;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{\x1B\x24B},
    code => sub {
      my ($irc, $args) = @_;
      $irc->send_notice ($args->{channel}, encode 'iso-2022-jp', 'このチャンネルでは文字コード UTF-8 を使ってください');
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
