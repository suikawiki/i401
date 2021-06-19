use strict;
use warnings;
use I401::Main;

my $irc = I401::Main->new_from_config({
    hostname => 'irc.example.org',
    tls => 0,
    port => 6667,
    nick => 'i401',
    password => undef,
    default_channels => ['#test'],
    http_hostname => '0.0.0.0',
    http_port => 4979,
    channel_passwords => {
      '#test' => 'testpassword',
    },
});

for (
  'I401::Rule::HTTPGet',
  'I401::Rule::Counter',
  'I401::Rule::TravisCIFailure',
) {
    eval qq{ require $_ } or die $@;
    $irc->register_rules ($_->get);
}

$irc->run;

## License: Public Domain.
