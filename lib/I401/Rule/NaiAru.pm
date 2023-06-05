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
    pattern => qr{(\w+)(?<!て)(?<!じゃ)ない[?？]*$},
    code => sub {
      my ($irc, $args) = @_;
      my $msg = "$1ある";
      $msg .= $suffix[rand @suffix];

      $irc->send_privmsg ($args->{channel}, $msg,
                          in_reply_to => $args->{message});
    },
  });
}

1;

=head1 ACKNOWLEDGEMENTS

Thanks to Rietion.  Rietion's spell is Rietion.

=head1 LICENSE

Copyright 2016-2023 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
