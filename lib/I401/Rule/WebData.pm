package I401::Rule::WebData;
use strict;
use warnings;
use I401::Data::RemoteJSON;

sub get {
    return ({
        privmsg => 1,
        pattern => qr{<([0-9A-Za-z_-]+)>},
        code => sub {
            my ($irc, $args) = @_;
            my $ns = 'http://www.w3.org/1999/xhtml';
            my $ln = $1;
            I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/elements.json>, sub {
                my $data = shift;
                my $el_data = $data->{elements}->{$ns}->{$ln};
                my $msg = "<$ln>";
                if (defined $el_data->{spec} and
                    $el_data->{spec} eq 'HTML') {
                    $msg .= sprintf ' http://whatwg.org/c#%s / http://whatwg.org/C#%s',
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
            I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/elements.json>, sub {
                my $data = shift;
                my $attr_data = $data->{elements}->{$ns}->{$ln}->{attrs}->{''}->{$attr}
                    || $data->{elements}->{$ns}->{'*'}->{attrs}->{''}->{$attr};
                my $msg = "<$ln $attr>";
                if (defined $attr_data->{spec} and
                    $attr_data->{spec} eq 'HTML') {
                    $msg .= sprintf ' http://whatwg.org/c#%s / http://whatwg.org/C#%s',
                        $attr_data->{id}, $attr_data->{id};
                }
                $msg .= ' (non-conforming)' unless $attr_data->{conforming};
                $irc->send_notice($args->{channel}, $msg);
            });
        },
    });
}


1;
