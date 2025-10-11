package I401::WSServer;
use strict;
use warnings;
use Digest::SHA qw(sha1);
use AnyEvent;
use AnyEvent::Socket;
use Promise;
use Promised::Flow;
use Promised::Command::Signals;
use Web::Transport::ProxyServerConnection;
use Web::Transport::Base64;
use JSON::PS;

use I401::Main;
push our @ISA, qw(I401::Main);

sub listen ($) {
  my $self = $_[0];
  my $aborted = 0;

  my $config = $self->config;
  die "Bad config |ws_hostname|\n" unless defined $config->{ws_hostname};
  die "Bad config |ws_port|\n" unless defined $config->{ws_port};
  warn "Listen: $config->{ws_hostname}:$config->{ws_port}\n";
  my $server = tcp_server $config->{ws_hostname}, $config->{ws_port}, sub {
    $self->{main_cv}->begin;
    my $con = Web::Transport::ProxyServerConnection->new_from_aeargs_and_opts (
      \@_, {
        handle_request => sub {
          my $args = $_[0];
          
          my $url = $args->{request}->{url};
          if ($url->path eq '/ws') {
            $args->{response}->{status} = 101;

            my $reader = $args->{request}->{messages};
            my $r = $reader->get_reader;

            my ($rr, $s, $c) = promised_cv;
            $args->{response}->{done} = $rr;

            (promised_until {
              return $r->read->then (sub {
                my $v = $_[0];
                return 'done' if $v->{done};
                
                my $rs = $v->{value}->{text_body};
                return not 'done' if not defined $rs;
                my $r2 = $rs->get_reader;
                my $w = '';
                return (promised_until {
                  return $r2->read->then (sub {
                    my $v = $_[0];
                    return 'done' if $v->{done};
                    $w .= ${$v->{value}};
                    return not 'done';
                  });
                  ## XXX Should we also cancel $r2 if it is too large?
                })->then (sub {
                  my $json = json_chars2perl $w;
                  if (defined $json and ref $json eq 'HASH') {
                    my $method = $json->{command} // '';
                    if ($method eq 'notice' or $method eq 'privmsg') {
                      $method = 'send_' . $method;
                      my $channel = $json->{channel} // '';
                      my $msg = $json->{message} // '';
                      if (length $channel and length $msg) {
                        $self->$method ($channel, $msg);
                      } else {
                        # XXX
                      }
                    } else {
                      # XXX
                    }
                  } else {
                    #XXX
                  }
                  ## XXX May be we should return error response if the
                  ## message is broken.
                  
                  if ($aborted) {
                    warn "aborted XXX";
                    $r->cancel ("WSServer aborted");
                    ## XXX This might not cleanly discard server's
                    ## internal objects.
                    return 'done';
                  }
                  return not 'done';
                });
              });
            })->then ($s, $c);
            
            return $args;
          }

          return {response => {status => 404}};
        },
      },
    );
    $con->closed->finally (sub { $self->{main_cv}->end });
  };
  ## Note that some messages might be discarded without sending to
  ## servers if the server is unlistened.

  $self->{main_cv}->begin;
  my ($r, $s) = promised_cv;
  $self->{wss_stop} = $s;
  $r->then (sub { $self->{main_cv}->end; $aborted = 1; undef $server });
  return undef;
} # listen

sub unlisten ($) {
  my $self = $_[0];
  ((delete $self->{wss_stop}) or sub { })->();
  return undef;
} # unlisten

1;

=head1 LICENSE

Copyright 2025 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
