package I401::Rule::TravisCIFailure;
use strict;
use warnings;

sub get {
    return ({
        notice => 1,
        pattern => qr<(The build.*?fail(?:ed|ing)\.)>,
        code => sub {
            my ($irc, $args) = @_;
            $irc->send_privmsg($args->{channel}, $1);
        },
    });
}

1;
