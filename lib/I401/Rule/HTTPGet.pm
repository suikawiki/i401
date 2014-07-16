package I401::Rule::HTTPGet;
use strict;
use warnings;
use Time::HiRes qw(time);
use Encode;
use AnyEvent::HTTP;
use AnyEvent::Util qw(run_cmd);

sub get {
    return ({
        privmsg => 1,
        pattern => qr<(?:(header|header_en)\s+)?(https?://[0-9A-Za-z_,\$!&:();./?+%\@=~#-]+)>,
        code => sub {
            my ($irc, $args) = @_;
            my $mode = 'process_' . ($1 || 'default');
            my $url = $2;
            __PACKAGE__->$mode($irc, $args, $url);
        },
    }, {
        privmsg => 1,
        pattern => qr<([Rr][Ff][Cc]\s*[0-9]+|draft-[0-9a-z-]+)>,
        code => sub {
            my ($irc, $args) = @_;
            my $name = lc $1;
            $name =~ s/\s+//g;
            my $url = qq<https://tools.ietf.org/html/$name>;
            $irc->send_notice($args->{channel}, $url);
            __PACKAGE__->process_default($irc, $args, $url);
        },
    });
}

sub process_default {
    my ($class, $irc, $args, $url) = @_;

    $irc->log("Get <$url>");
    my $start_time = time;
    http_get $url, sub {
        my ($data, $headers) = @_;
        $data = '' unless defined $data;
        my $title = '';
        my $charset = 'utf-8';
        if (($headers->{'content-type'} || '') =~ /charset=(\S+)/) {
            $charset = {'euc-jp' => 'euc-jp',
                        'shift_jis' => 'windows-31j'}->{lc $1} || $charset;
        }
        if ($data =~ m{<title>(.*?)</title>}s) {
            $title = decode $charset, $1;
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
}

sub process_header {
    my ($class, $irc, $args, $url) = @_;

    my $pid;
    my $in_header = 1;
    my $header = [];
    $irc->log("Get <$url>");
    run_cmd(
        ['curl', '-D', '-', $url],
        '>' => sub {
            return unless $in_header;
            my $data = shift;
            if ($data =~ /\x0D\x0A\x0D\x0A/) {
                push @$header, [split /\x0D\x0A\x0D\x0A/, $data, 2]->[0];
                kill 'INT', $pid;
                undef $in_header;
            } else {
                push @$header, $data;
            }
        },
        '$$' => \$pid,
    )->cb(sub {
        my $msg = join '', @$header;
        for (split /\x0D\x0A/, $msg) {
            tr/\x0D\x0A/  /;
            $irc->send_notice($args->{channel}, $_);
        }
    });
}

sub process_header_en {
    my ($class, $irc, $args, $url) = @_;

    my $pid;
    my $in_header = 1;
    my $header = [];
    $irc->log("Get <$url>");
    run_cmd(
        ['curl', '--header', 'Accept-Language: en', '-D', '-', $url],
        '>' => sub {
            return unless $in_header;
            my $data = shift;
            if ($data =~ /\x0D\x0A\x0D\x0A/) {
                push @$header, [split /\x0D\x0A\x0D\x0A/, $data, 2]->[0];
                kill 'INT', $pid;
                undef $in_header;
            } else {
                push @$header, $data;
            }
        },
        '$$' => \$pid,
    )->cb(sub {
        my $msg = join '', @$header;
        for (split /\x0D\x0A/, $msg) {
            tr/\x0D\x0A/  /;
            $irc->send_notice($args->{channel}, $_);
        }
    });
}

1;
