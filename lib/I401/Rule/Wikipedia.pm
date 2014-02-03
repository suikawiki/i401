package I401::Rule::Wikipedia;
use strict;
use warnings;
use utf8;
use Encode;
use AnyEvent::HTTP;

{
    my $Host;
    sub host {
        if (@_ > 1) {
            $Host = $_[1];
        }
        return unless defined wantarray;
        return $Host || die "Host of <https://github.com/geocol/perl-mediawiki-parser/blob/master/bin/wpserver.psgi> is not set";
    }
}

sub pe ($) {
    my $s = encode 'utf-8', shift;
    $s =~ s{([^A-Za-z0-9_-])}{sprintf '%%%02X', ord $1}ge;
    return $s;
}

sub get {
    return ({
        privmsg => 1,
        pattern => qr<(.+)とは>,
        code => sub {
            my ($irc, $args) = @_;
            my $word = $1;
            $word =~ s/^\s+//g;
            $word =~ s/\s+$//g;
            $word =~ s/\s+/ /g;
            return unless length $word;
            my $lang = 'ja';

            my $url = sprintf q<http://%s/%s/abstract?name=%s>,
                __PACKAGE__->host,
                pe $lang,
                pe $word;
            $irc->log("Get <$url>...");
            http_get $url, sub {
                my ($data, $headers) = @_;
                if ($headers->{Status} == 200 and
                    length $data) {
                    $data = decode 'utf-8', $data;
                    $data =~ s/^\s+//;
                    $data =~ s/\s+$//;
                    $data =~ s/\s+/ /g;
                    $irc->send_notice($args->{channel}, $data);
                } else {
                    $irc->send_notice($args->{channel}, "$word\ってなんですか");
                }
            };
        },
    });
}

1;
