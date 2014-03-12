package I401::Rule::Gbr;
use strict;
use warnings;
use utf8;

sub get ($) {
  return ({
    notice => 1,
    privmsg => 1,
    pattern => qr{\bgbr\b},
    code => sub {
      my ($irc, $args) = @_;
      $irc->send_notice ($args->{channel}, "おはようございます");
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
