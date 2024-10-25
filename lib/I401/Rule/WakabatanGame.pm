package I401::Rule::WakabatanGame;
use strict;
use warnings;
use utf8;

my $string = 'わかばたん';
my $channel_sequences = {};

sub get {
    return ({
        privmsg => 1,
        pattern => qr{^.$},
        code => sub {
            my ($irc, $args) = @_;
            my $seq = $channel_sequences->{$args->{channel}} ||= [ split '', $string ];
            if ($seq->[0] eq $args->{message}->text) {
                push @$seq, shift @$seq;
                $irc->send_notice($args->{channel}, $seq->[0]);
                push @$seq, shift @$seq;
            }
        }
    });
}

1;

=head1 LICENSE

Copyright 2014 pokutuna <popopopopokutuna@gmail.com>.

Copyright 2014 Hatena <http://www.hatena.ne.jp/company/>.

Copyright 2024 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
