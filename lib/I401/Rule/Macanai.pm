package I401::Rule::Macanai;
use strict;
use warnings;
use utf8;
use I401::Data::Twitter;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr/ペコ死|ぺこ死|ぺこし/,
    code => sub {
      my ($irc, $args) = @_;
      I401::Data::Twitter->get (
        $irc->config,
        q<statuses/user_timeline.json?screen_name=macanai&count=1>,
        sub {
          my $json = shift;
          $irc->send_notice ($args->{channel}, $json->[0]->{text});
        },
      );
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
