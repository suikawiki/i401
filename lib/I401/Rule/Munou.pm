package I401::Rule::Munou;
use strict;
use warnings;
use utf8;
use Encode;
use Path::Class;
use AnyEvent;
use AnyEvent::Util qw(run_cmd);

my $RepoURL;
my $FileName;
my $TempD;

sub set_source ($$$) {
  my ($class, $repo_url, $file_name, $temp_d) = @_;
  $RepoURL = $repo_url;
  $FileName = $file_name;
  $TempD = $temp_d;
}

my $Data = {};
my $Updater;

sub start_updater ($) {
  $Updater = AE::timer 1, 60*(60 + 100 * rand 1), sub {
    warn __PACKAGE__ . ": Check for updates...\n";
    if (defined $RepoURL and defined $FileName and defined $TempD) {
      my $temp_repo_d = $TempD->subdir ('munou-data-repo');
      (run_cmd ['git', 'clone', $RepoURL, $temp_repo_d])->cb (sub {
        (run_cmd "cd \Q$temp_repo_d\E && git pull")->cb (sub {
          my $f = $temp_repo_d->file ($FileName);
          if (-f $f) {
            $Data = {};
            for (grep { length and not /^#/ } map { s/^\s+//; $_ } split /\x0D?\x0A/, decode 'utf-8', scalar $f->slurp) {
              my ($key, $value) = split /=/, $_, 2;
              next unless defined $value;
              $Data->{$key} = [grep { length } split /\|/, $value];
            }
            warn __PACKAGE__ . ": Data reloaded\n";
          }
        });
      });
    }
  };
} # start_updater

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{(.+)},
    code => sub {
      my ($irc, $args) = @_;
      my $input = $1;
      my @matched;
      for my $key (keys %$Data) {
        if ($input =~ /(\Q$key\E)/) {
          $matched[length $1] = $key;
        }
      }
      if (@matched) {
        my $values = $Data->{$matched[-1]};
        my $msg = $values->[rand @$values];
        $irc->send_notice($args->{channel}, $msg);
      }
    },
  }, {
    privmsg => 1,
    pattern => qr{起きろ > i401},
    code => sub {
      my ($irc, $args) = @_;
      __PACKAGE__->start_updater;
    },
  });
}

1;
