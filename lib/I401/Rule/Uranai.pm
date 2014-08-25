package I401::Rule::Uranai;
use strict;
use warnings;
use utf8;
use I401::Data::RemoteJSON;

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr<(
牡羊座|
牡牛座|
双子座|
蟹座|
獅子座|
乙女座|
天秤座|
蠍座|
射手座|
山羊座|
水瓶座|
魚座
    )>x,
    code => sub {
      my ($irc, $args) = @_;
      my $sign = $1;
      my $today = [gmtime];
      $today = sprintf '%04d/%02d/%02d',
          $today->[5]+1900, $today->[4]+1, $today->[3];
      my $url = q<http://api.jugemkey.jp/api/horoscope/free/> . $today;
      I401::Data::RemoteJSON->get ($url, sub {
        my $data = shift;
        $data = ref $data eq 'HASH' ? $data->{horoscope} : {};
        $data = [values %$data]->[0];
        if (ref $data eq 'ARRAY') {
          $data = [grep { ref $_ eq 'HASH' and $_->{sign} eq $sign } @$data]->[0];
          if (defined $data) {
            my $msg = sprintf '[%s %s] %sラッキーカラーは%s、ラッキーアイテムは%s。',
                $today, $sign,
                $data->{content}, $data->{color}, $data->{item};
            $irc->send_notice($args->{channel}, $msg);
          }
        }
      });
    },
  });
} # get

1;

=pod

Web ad Fortune 無料API <http://jugemkey.jp/api/waf/api_free.php>.

powerd by <a href="http://jugemkey.jp/api/waf/api_free.php">JugemKey</a>
【PR】<a href="http://www.tarim.co.jp/">原宿占い館 塔里木</a>

=cut
