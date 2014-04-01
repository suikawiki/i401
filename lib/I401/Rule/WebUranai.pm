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
  }, {
    privmsg => 1,
    pattern => qr{ラッキー\s*(?:URL|URI|IRI)\s*[Ss]cheme},
    code => sub {
      my ($irc, $args) = @_;
      I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/url-schemes.json>, sub {
        my $data = shift;
        my $schemes = [keys %$data];
        my $scheme = $schemes->[rand @$schemes];
        $irc->send_notice
            ($args->{channel},
             sprintf 'ラッキー URL scheme は %s: %sです',
                 $scheme,
                 ($data->{$scheme}->{ill_formed} ? '(構文エラー) ' : ''));
      });
    },
  }, {
    privmsg => 1,
    pattern => qr{ラッキー\s*MIME\s*(?:型|タイプ|[Tt]ype)},
    code => sub {
      my ($irc, $args) = @_;
      I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/mime-types.json>, sub {
        my $data = shift;
        my $types = [grep { $data->{$_}->{type} eq 'subtype' } keys %$data];
        my $type = $types->[rand @$types];
        $irc->send_notice
            ($args->{channel},
             sprintf 'ラッキー MIME 型は %s です', $type);
      });
    },
  }, {
    privmsg => 1,
    pattern => qr{ラッキー(?:通貨|貨幣)},
    code => sub {
      my ($irc, $args) = @_;
      I401::Data::RemoteJSON->get(q<https://raw.github.com/manakai/data-web-defs/master/data/langtags.json>, sub {
        my $data = shift;
        my $types = [keys %{$data->{u_cu}}];
        my $type = $types->[rand @$types];
        $irc->send_notice
            ($args->{channel},
             sprintf 'ラッキー通貨は %s (%s) です',
                 uc $type,
                 join ' ', @{$data->{u_cu}->{$type}->{Description} or []});
      });
    },
  });
} # get

1;
