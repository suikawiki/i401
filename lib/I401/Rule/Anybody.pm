package I401::Rule::Anybody;
use strict;
use warnings;
use utf8;

my $BeggingText = [
    'お願いします',
    'よろすく',
    'まかせた',
    '頼む',
    'おにゃーしゃー',
    'じゃあそれで',
];

sub get ($) {
    return ({
        privmsg => 1,
        pattern => qr{(?:誰|だれ)か},
        code    => sub {
            my ($irc, $args) = @_;
            my $users = $irc->get_channel_users($args->{channel});
            my $anybody = $users->[int(rand(@$users))];
            my $begging = $BeggingText->[int(rand(@$BeggingText))];
            $irc->send_privmsg($args->{channel}, join(' > ', $begging, $anybody));
        },
    });
}

1;
