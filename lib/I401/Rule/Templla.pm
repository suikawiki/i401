package I401::Rule::Templla;
use strict;
use warnings;
use utf8;
use Encode;
use Path::Class;
use AnyEvent;
use I401::Data::RemoteJSON;

my $URL = q<http://templla.com/api/list>;
my $Data = {};
my $Updater;

sub start_updater ($) {
  $Updater = AE::timer 1, 60*(60 + 100 * rand 1), sub {
    warn __PACKAGE__ . ": Check for updates...\n";
    I401::Data::RemoteJSON->get ($URL, sub {
      my $src = $_[0];
      if (ref $src eq 'ARRAY') {
        $Data = {};
        for (@$src) {
          if (ref $_ eq 'HASH') {
            push @{$Data->{$_->{title}} ||= []}, $_->{body};
          }
        }
        warn __PACKAGE__ . ": Data reloaded\n";
      }
    }, max_age => 60*10);
  };
} # start_updater

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+)},
    code => sub {
      my ($irc, $args) = @_;
      my $input = $1;
      my @matched;
      for my $key (keys %$Data) {
        if ($input =~ /(\Q$key\E)/) {
          $matched[length $1] = $key;
        }
      }
      if (@matched) {
        my $values = $Data->{$matched[-1]};
        my $msg = $values->[rand @$values];
        $irc->send_notice($args->{channel}, $msg);
      }
    },
  }, {
    privmsg => 1,
    pattern => qr{起きろ > i401},
    code => sub {
      my ($irc, $args) = @_;
      __PACKAGE__->start_updater;
    },
  });
}

1;
