package I401::Fetch;
use strict;
use warnings;
use Promise;
use Web::URL;
use Web::Transport::BasicClient;

sub get_by_url_string ($$) {
  my ($class, $url_string) = @_;

  my $url = Web::URL->parse_string ($url_string);
  return Promise->reject ("Bad URL <$url_string>")
      unless defined $url and $url->is_http_s;
  
  my $client = Web::Transport::BasicClient->new_from_url ($url);
  return $client->request (
    method => 'GET',
    url => $url,
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    return $res;
  })->finally (sub {
    return $client->close;
  });
} # get_by_url_string

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
