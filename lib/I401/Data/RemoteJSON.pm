package I401::Data::RemoteJSON;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP;
use JSON::PS;

my $CachedData = {};

sub get ($$$;%) {
  my ($class, $url, $code, %args) = @_;
  my $max_age = $args{max_age} || 60*60;
  if ($CachedData->{$url} and time < $CachedData->{$url}->{time} + $max_age) {
    AE::postpone { $code->($CachedData->{$url}->{data}) };
    return;
  }

  warn "<$url>...\n";
  http_get $url, sub {
    my ($data) = @_;
    my $json = json_bytes2perl $data;
    $CachedData->{$url} = {data => $json, time => time} if $json;
    $code->($json);
  };
} # get

1;
