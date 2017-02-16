package I401::Rule::Amazon;
use strict;
use warnings;
use Web::URL::Encoding qw(percent_encode_c);
use I401::Data::RemoteJSON;

our $AmazonSearchProxyURL ||= 'https://amazonsearch.invalid/';
our $AmazonSearchProxyOrigin;
our $ASINProxyURL ||= 'https://asin.invalid/';

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr<Amazon\s*\s*:(.+)>x,
    code => sub {
      my ($irc, $args) = @_;
      my $q = $1;
      my $url = $AmazonSearchProxyURL . q<?q=> . percent_encode_c $q;
      I401::Data::RemoteJSON->get ($url, sub {
        my $data = shift;
        my $i = 0;
        for my $url (map { $ASINProxyURL . $_->{ASIN} } @{$data->{items}}) {
          $irc->send_privmsg ($args->{channel}, $url);
          last if ++$i > 2;
        }
      }, origin => $AmazonSearchProxyOrigin);
    },
  });
} # get

1;
