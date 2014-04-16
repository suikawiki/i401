package I401::Rule::TravisCIFailure;
use strict;
use warnings;

sub get ($) {
  return ({
    notice => 1,
    pattern => qr<(The build.*?(?:(?:fail|error)(?:ed|ing)|broken)\.)>,
    code => sub {
      my ($irc, $args) = @_;
      $irc->send_privmsg ($args->{channel}, $1);
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
