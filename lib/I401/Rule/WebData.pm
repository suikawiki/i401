package I401::Rule::WebData;
use strict;
use warnings;
use AnyEvent;
use Encode;
use AnyEvent::HTTP;
use AnyEvent::Util qw(run_cmd);
use JSON::Functions::XS qw(json_bytes2perl);

sub get {
    return ({
        privmsg => 1,
        pattern => qr{<([0-9A-Za-z_-]+)>},
        code => sub {
            my ($irc, $args) = @_;
            my $ns = 'http://www.w3.org/1999/xhtml';
            my $ln = $1;
            __PACKAGE__->get_json('elements', sub {
                my $data = shift;
                my $el_data = $data->{elements}->{$ns}->{$ln};
                my $msg = '';
                if (defined $el_data->{spec} and
                    $el_data->{spec} eq 'HTML') {
                    $msg .= sprintf '<http://whatwg.org/c#%s> <http://whatwg.org/C#%s>',
                        $el_data->{id}, $el_data->{id};
                }
                $msg .= ' (non-conforming)' unless $el_data->{conforming};
                $irc->send_notice($args->{channel}, $msg);
            });
        },
    }, {
        privmsg => 1,
        pattern => qr{<([0-9A-Za-z_-]+)\s+([0-9A-Za-z_-]+)(?:="")?>},
        code => sub {
            my ($irc, $args) = @_;
            my $ns = 'http://www.w3.org/1999/xhtml';
            my $ln = $1;
            my $attr = $2;
            __PACKAGE__->get_json('elements', sub {
                my $data = shift;
                my $attr_data = $data->{elements}->{$ns}->{$ln}->{attrs}->{''}->{$attr}
                    || $data->{elements}->{$ns}->{'*'}->{attrs}->{''}->{$attr};
                my $msg = '';
                if (defined $attr_data->{spec} and
                    $attr_data->{spec} eq 'HTML') {
                    $msg .= sprintf '<http://whatwg.org/c#%s> <http://whatwg.org/C#%s>',
                        $attr_data->{id}, $attr_data->{id};
                }
                $msg .= ' (non-conforming)' unless $attr_data->{conforming};
                $irc->send_notice($args->{channel}, $msg);
            });
        },
    });
}

my $CachedData = {};

sub get_json {
    my ($class, $url, $code) = @_;
    if ($CachedData->{$url} and $CachedData->{$url}->{time} + 60*60 < time) {
        AE::postpone { $code->($CachedData->{$url}->{data}) };
    }
    http_get qq<https://raw.github.com/manakai/data-web-defs/master/data/$url.json>, sub {
        my ($data) = @_;
        my $json = json_bytes2perl $data;
        $CachedData->{$json} = {data => $json, time => time} if $json;
        $code->($json);
    };
}

1;
