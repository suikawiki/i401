package I401::Rule::Hyakunin;
use strict;
use warnings;
use I401::Data::RemoteJSON;

sub get {
  return ({
    privmsg => 1,
    pattern => qr{^(.{1,40})$},
    code => sub {
      my ($irc, $args) = @_;
      my $text = $1;
      $text =~ s/\s+/ /;
      $text =~ s/\A //;
      $text =~ s/ \z//;
      I401::Data::RemoteJSON->get (q<https://gist.githubusercontent.com/wakaba/8363dc27f4c54f76b4a7/raw/485bfbc7341196ec4bbd8589e06ab03df784b0a8/hyakunin.json>, sub {
        my $data = shift;
        for (@$data) {
          if ($_->{bodyKana} =~ /^\Q$text\E/ or
              $_->{bodyKanji} =~ /\Q$text\E/) {
            $irc->send_notice($args->{channel}, sprintf '%s -- %s', $_->{bodyKanji}, $_->{nameKanji});
            last;
          }
        }
      }, max_age => 60*60*24*10);
    },
  });
} # get

1;
