package I401::Data::Twitter;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP;
use Web::UserAgent::OAuth;
use JSON::PS;

my $CachedData = {};

sub get ($$$$;%) {
  my ($class, $config, $url, $code, %args) = @_;
  my $max_age = $args{max_age} || 60*60;
  if ($CachedData->{$url} and time < $CachedData->{$url}->{time} + $max_age) {
    AE::postpone { $code->($CachedData->{$url}->{data}) };
    return;
  }

  warn "<$url>...\n";
  my $oauth = Web::UserAgent::OAuth->new (
    url_scheme => 'https',
    request_method => 'GET',
    request_url => q<https://api.twitter.com/1.1/> . $url,
    http_host => 'api.twitter.com',
    oauth_consumer_key => $config->{twitter_consumer_key},
    client_shared_secret => $config->{twitter_consumer_secret},
    oauth_token => $config->{twitter_access_token},
    token_shared_secret => $config->{twitter_access_token_secret},
  );
  $oauth->authenticate_by_oauth1(container => 'query');
  http_get $oauth->request_url, sub {
    my ($data) = @_;
    my $json = json_bytes2perl $data;
    $CachedData->{$url} = {data => $json, time => time} if $json;
    $code->($json);
  };
} # get

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
