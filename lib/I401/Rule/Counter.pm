package I401::Rule::Counter;
use strict;
use warnings;

my $Counter = {};

sub get {
    return ({
        privmsg => 1,
        pattern => qr<(\w+)\+\+>,
        code => sub {
            my ($irc, $args) = @_;
            my $value = $1;
            $Counter->{$value}->{count}++;
            $Counter->{$value}->{increment}++;
            my $sent_text = sprintf '%s: %d (%d++, %d--)',
                $value, $Counter->{$value}->{count},
                $Counter->{$value}->{increment},
                $Counter->{$value}->{decrement} || 0;
            $irc->send_notice($args->{channel}, $sent_text);
        },
    },
    {
        privmsg => 1,
        pattern => qr<(\w+)-->,
        code => sub {
            my ($irc, $args) = @_;
            my $value = $1;
            $Counter->{$value}->{count}--;
            $Counter->{$value}->{decrement}++;
            my $sent_text = sprintf '%s: %d (%d++, %d--)',
                $value, $Counter->{$value}->{count},
                $Counter->{$value}->{increment} || 0,
                $Counter->{$value}->{decrement};
            $irc->send_notice($args->{channel}, $sent_text);
        },
    });
}

1;
