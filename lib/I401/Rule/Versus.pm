package I401::Rule::Versus;
use strict;
use warnings;
use utf8;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+\s[Vv][Ss]\.?\s.+)},
    code => sub {
      my ($irc, $args) = @_;
      my @item = grep { length } split /\s+[Vv][Ss]\.?\s+/, $1;
      $irc->send_notice ($args->{channel}, $item[rand @item]);
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
