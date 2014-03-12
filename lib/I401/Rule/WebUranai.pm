package I401::Rule::WebUranai;
use strict;
use warnings;
use utf8;
use I401::Data::RemoteJSON;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{ラッキー要素},
    code => sub {
      my ($irc, $args) = @_;
      my $ns = 'http://www.w3.org/1999/xhtml';
      I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/elements.json>, sub {
        my $data = shift;
        my $elements = [keys %{$data->{elements}->{$ns}}];
        my $ln = $elements->[rand @$elements];
        $irc->send_notice($args->{channel}, sprintf 'ラッキー要素は <%s> です☆', $ln);
      });
    },
  });
} # get

1;
