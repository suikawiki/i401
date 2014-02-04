package I401::Rule::Uranai;
use strict;
use warnings;
use utf8;
use AnyEvent::HTTP;
use JSON::Functions::XS qw(json_bytes2perl);

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
      __PACKAGE__->with_data ($today => sub {
        my $data = shift;
        $data = [grep { ref $_ eq 'HASH' and $_->{sign} eq $sign } @$data]->[0];
        if (defined $data) {
          my $msg = sprintf '[%s %s] %sラッキーカラーは%s、ラッキーアイテムは%s。',
              $today, $sign,
              $data->{content}, $data->{color}, $data->{item};
          $irc->send_notice($args->{channel}, $msg);
        }
      });
    },
  });
} # get

my $Data = {};

sub with_data ($$$) {
  my ($class, $today, $code) = @_;
  if ($Data->{$today}) {
    return $code->($Data->{$today});
  }

  my $url = q<http://api.jugemkey.jp/api/horoscope/free/> . $today;
  http_get $url, sub {
    my ($data, $headers) = @_;
    if ($headers->{Status} == 200) {
warn $data;
      $data = json_bytes2perl $data;
      $data = ref $data eq 'HASH' ? $data->{horoscope} : {};
      $data = $data->{each %$data};
      if (ref $data eq 'ARRAY') {
        $Data->{$today} = $data;
        $code->($data);
      }
    }
  };
} # _with_data

1;

=pod

Web ad Fortune 無料API <http://jugemkey.jp/api/waf/api_free.php>.

powerd by <a href="http://jugemkey.jp/api/waf/api_free.php">JugemKey</a>
【PR】<a href="http://www.tarim.co.jp/">原宿占い館 塔里木</a>

=cut
