package I401::Data::RemoteJSON;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP;
use JSON::Functions::XS qw(json_bytes2perl);

my $CachedData = {};

sub get ($$$;%) {
  my ($class, $url, $code, %args) = @_;
  my $max_age = $args{max_age} || 60*60;
  if ($CachedData->{$url} and $CachedData->{$url}->{time} + $max_age < time) {
    AE::postpone { $code->($CachedData->{$url}->{data}) };
  }
  http_get $url, sub {
    my ($data) = @_;
    my $json = json_bytes2perl $data;
    $CachedData->{$json} = {data => $json, time => time} if $json;
    $code->($json);
  };
} # get

1;
