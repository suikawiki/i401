package I401::Rule::NemuokaSan;
use strict;
use warnings;
use utf8;

my $texts = [
    '(っ=﹏=c) .｡o○ ( ねむいですぅ... )',
    '(っ=﹏=c) .｡o○ ( 眠いなら寝る!! )',
];

sub get {
    return ({
        privmsg => 1,
        pattern => qr{ねむい},
        code    => sub {
            my ($irc, $args) = @_;
            $irc->send_notice($args->{channel}, $texts->[int(rand(@$texts))]);
        }
    });
}

1;
