package I401::Rule::ForwardMentioned;
use strict;
use warnings;
use Web::URL;

use I401::Fetch;

my $URL;
sub set_url_string ($$) {
  $URL = Web::URL->parse_string ($_[1]) or die "Bad URL specified: <$_[1]>";
} # set_url_string

sub get ($) {
  return ({
    mentioned => 1,
    code => sub {
      my ($main, $args) = @_;

      my $m = $args->{message};
      my $data = {
        protocol => $m->protocol,
        connection_name => $m->connection_name,
        message => $m->raw,
        id => $m->id,
      };

      return I401::Fetch->post_data ($URL, $data);
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2023 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
