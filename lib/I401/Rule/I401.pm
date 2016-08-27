package I401::Rule::I401;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use AnyEvent;
use AnyEvent::Util qw(run_cmd);
use Time::Local qw(timegm_nocheck);

my $RootPath = path (__FILE__)->parent->parent->parent->parent;

sub get_git_data_as_cv () {
  my $cv = AE::cv;
  my $in = '';
  run_cmd
      ("cd \Q$RootPath\E && git log HEAD --format='format:%at %H' -n 1",
       '>' => sub {
         $in .= $_[0] if defined $_[0];
       })->cb (sub {
    my $d = [split / /, $in];
    my $data = {at => $d->[0], H => $d->[1]};
    $cv->send ($data);
  });
  return $cv;
} # get_git_data_as_cv

sub get ($) {
  return ({
    privmsg => 1,
    pattern => qr{イオナのこと},
    code => sub {
      my ($irc, $args) = @_;
      my $local_data;
      my $remote_data;
      my $cv = AE::cv;
      $cv->begin;
      $cv->begin;
      get_git_data_as_cv->cb (sub {
        $local_data = $_[0]->recv;
        $cv->end;
      });
      $cv->begin;
      I401::Data::RemoteJSON->get(q<https://api.github.com/repos/wakaba/i401/commits/master>, sub {
        $remote_data = shift;
        $cv->end;
      });
      $cv->end;
      $cv->cb (sub {
        my $local_date = $local_data->{at};
        my @local_date = gmtime $local_date;
        my $s = sprintf 'i401 %s (%04d-%02d-%02d %02d:%02d:%02d UTC)',
            (substr $local_data->{H}, 0, 10),
            $local_date[5]+1900, $local_date[4]+1, $local_date[3],
            $local_date[2], $local_date[1], $local_date[0];
        $irc->send_notice ($args->{channel}, $s);

        my $remote_date = 0;
        if ($remote_data->{commit}->{author}->{date} =~ /^([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)Z$/) {
          $remote_date = timegm_nocheck ($6, $5, $4, $3, $2-1, $1);
        }
        
        if ($remote_date > $local_date) {
          $irc->send_notice ($args->{channel}, sprintf 'わたしは %s s 古いバージョンです', $remote_date - $local_date);
        }
      });
    },
  });
} # get

1;

=head1 LICENSE

Copyright 2014-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
