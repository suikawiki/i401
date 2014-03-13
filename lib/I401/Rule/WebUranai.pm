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
        my $elements = [grep { not $_ eq '*' } keys %{$data->{elements}->{$ns}}];
        my $ln = $elements->[rand @$elements];
        my $def = $data->{elements}->{$ns}->{$ln};
        $irc->send_notice($args->{channel}, sprintf 'ラッキー要素は <%s> (%s) です☆', $ln, (join ', ', (defined $def->{desc} ? ($def->{desc}) : ()), ($def->{conforming} ? () : ('不適合'))));
      });
    },
  }, {
    privmsg => 1,
    pattern => qr{ラッキー属性},
    code => sub {
      my ($irc, $args) = @_;
      my $ns = 'http://www.w3.org/1999/xhtml';
      I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/elements.json>, sub {
        my $data = shift;
        my $elements = [keys %{$data->{elements}->{$ns}}];
        my $attrs = [map { my $el = $_; map { [$el, $_] } keys %{$data->{elements}->{$ns}->{$_}->{attrs}->{''} or {}} } @$elements];
        my $attr = $attrs->[rand @$attrs];
        my $def = $data->{elements}->{$ns}->{$attr->[0]}->{attrs}->{''}->{$attr->[1]};
        $irc->send_notice($args->{channel}, sprintf 'ラッキー属性は <%s %s=""> (%s) です☆', $attr->[0], $attr->[1], (join ', ', (defined $def->{desc} ? ($def->{desc}) : ()), ($attr->[0] eq 'embed' ? $def->{non_conforming} ? ('不適合') : () : $def->{conforming} ? () : ('不適合'))));
      });
    },
  });
} # get

1;
