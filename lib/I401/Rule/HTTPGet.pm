package I401::Rule::HTTPGet;
use strict;
use warnings;
use Time::HiRes qw(time);
use Encode;
use AnyEvent::HTTP;

sub get {
    return ({
        privmsg => 1,
        pattern => qr<(https?://[0-9A-Za-z_,\$!&:();./?+%\@=#-]+)>,
        code => sub {
            my ($irc, $args) = @_;

            $irc->log("Get <$1>");
            my $start_time = time;
            http_get $1, sub {
                my ($data, $headers) = @_;
                $data = '' unless defined $data;
                my $title = '';
                if ($data =~ m{<title>(.*?)</title>}s) {
                    $title = decode 'utf-8', $1;
                }
                my $msg = sprintf '[%d %s, %s %.3f KB %.3f s] %s',
                    $headers->{Status},
                    (decode 'utf-8', $headers->{Reason}),
                    (defined $headers->{'content-type'}
                         ? $headers->{'content-type'} : '(no Content-Type)'),
                    (length $data) / 1024,
                    time - $start_time,
                    $title;
                $irc->send_notice($args->{channel}, $msg);
            };
        },
    });
}

1;
