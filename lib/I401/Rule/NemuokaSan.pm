package I401::Rule::NemuokaSan;
use strict;
use warnings;
use utf8;

my $texts = [
    '(っ=﹏=c) .｡o○ ( ねむいですぅ... )',
    '(っ=﹏=c) .｡o○ ( 眠いなら寝る!! )',
    'ヾ(*＞ヮ＜)ﾉ" お供します、お布団の中まで',
];

sub get {
    return ({
        privmsg => 1,
        pattern => qr{ねむい|nemui},
        code    => sub {
            my ($irc, $args) = @_;
            $irc->send_notice($args->{channel}, $texts->[int(rand(@$texts))]);
        }
    }, {
        notice => 1,
        privmsg => 1,
        pattern => qr{\bgbr\b},
        code => sub {
            my ($irc, $args) = @_;
            $irc->send_notice($args->{channel}, "おはようございます");
        },
    });
}

1;
