package I401::Fetch;
use strict;
use warnings;
use Promise;
use Web::URL;
use Web::Transport::BasicClient;
use JSON::PS;

sub get_by_url_string ($$;%) {
  my ($class, $url_string, %args) = @_;

  my $url = Web::URL->parse_string ($url_string);
  return Promise->reject ("Bad URL <$url_string>")
      unless defined $url and $url->is_http_s;
  
  my $client = Web::Transport::BasicClient->new_from_url ($url);
  return $client->request (
    method => 'GET',
    headers => {
      %{$args{headers} or {}},
    },
    url => $url,
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    return $res;
  })->finally (sub {
    return $client->close;
  });
} # get_by_url_string

my $Clients = {};
our $ClientOptions;

sub post_data ($$$;%) {
  my ($class, $url, $data, %args) = @_;

  my $client = $Clients->{$url->get_origin->to_ascii} ||= Web::Transport::BasicClient->new_from_url ($url, $ClientOptions);
  return $client->request (
    url => $url,
    method => 'POST',
    headers => {
      'content-type' => 'application/json; charset=utf-8',
      %{$args{headers} or {}},
    },
    body => perl2json_bytes ($data),
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
  });
} # post_data

sub close ($) {
  my @p;
  for (values %$Clients) {
    push @p, $_->close;
  }
  $Clients = {};
  return Promise->all (\@p);
} # close

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2022-2023 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
