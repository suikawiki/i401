package I401::Protocol::Slack;
use strict;
use warnings;
use JSON::PS;
use Web::URL;
use Web::Transport::ConnectionClient;
use Web::Transport::WSClient;

sub new_from_i401_and_config_and_logger ($$$) {
  return bless {i401 => $_[1], config => $_[2], logger => $_[3]}, $_[0];
} # new

sub config ($) {
  return $_[0]->{config};
} # config

sub log ($$;%) {
  my ($self, $text, %args) = @_;
  $self->{logger}->($text);
} # log

sub connect ($) {
  my $self = $_[0];
  my $url1 = Web::URL->parse_string (q<https://slack.com/api/rtm.start>);
  my $http = $self->{http} = Web::Transport::ConnectionClient->new_from_url ($url1);
  $http->request (url => $url1, params => {
    token => $self->config->{slack_token},
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $json = json_bytes2perl $res->body_bytes;
    my $url2 = Web::URL->parse_string ($json->{url}) or die "No URL";
    $self->{user_id} = $json->{self}->{id};

    my $current_data = '';
    return Web::Transport::WSClient->new (
      url => $url2,
      cb => sub {
        my ($client, $data, $is_text) = @_;
        if (defined $is_text) { # text or binary
          if (defined $data) { # frame data
            $current_data .= $data;
          } else { # end of frame
            if ($is_text) { # text
              #warn "Received |$current_data| (text)";
              my $json = json_bytes2perl $current_data;
              if (defined $json and ref $json eq 'HASH') {
                if ($json->{type} eq 'message' and
                    not defined $json->{message} and
                    not defined $json->{bot_id}) {
                  $self->{i401}->process_by_rules({
                    #prefix => $msg->{prefix},
                    channel => $json->{channel},
                    command => 'PRIVMSG',
                    text => $json->{text},
                  });
                }
              }
            } else { # binary
              #warn "Received |$current_data| (binary)";
            }
            $current_data = '';
          }
        } else { # handshake done
          $current_data = '';
          $self->{ws} = $client;
        }
      }, # cb
    )->then (sub {
      my $res = $_[0];
      if ($res->ws_closed_cleanly) {
        $self->log ("Connection cleanly closed");
      } else {
        $self->log ("Connection closed: " . $res->ws_code . " " . $res->ws_reason);
      }
    });
  })->catch (sub {
    $self->log ("Error: $_[0]");
  })->then (sub {
    delete $self->{ws};
    delete $self->{http};
    return $http->close;
  })->then (sub {
    $self->log ('Disconnected', class => 'error');
    if ($self->{shutdown}) {
      (delete $self->{onshutdown})->() if $self->{onshutdown};
    } else {
      $self->reconnect;
    }
  });
  return undef;
} # connect

sub set_shutdown_mode ($$) {
  $_[0]->{shutdown} = 1;
  $_[0]->{onshutdown} = $_[1];
} # set_shutdown_mode

sub disconnect ($) {
  my $self = shift;
  if (defined $self->{ws}) {
    $self->{ws}->close;
  } else {
    if ($self->{shutdown}) {
      (delete $self->{onshutdown})->() if $self->{onshutdown};
    }
  }
} # disconnect

sub reconnect ($) {
  my $self = shift;
  my $timer; $timer = AE::timer 10, 0, sub {
    $self->connect;
    undef $timer;
  };
} # reconnect

sub send_notice ($$$) {
  my ($self, $channel, $text) = @_;
  $text =~ s/\A[\x0D\x0A]+//;
  $text =~ s/[\x0D\x0A]+\z//;
  $self->{http}->request
      (method => 'POST',
       url => Web::URL->parse_string (q<https://slack.com/api/chat.postMessage>),
       params => {token => $self->config->{slack_token},
                  as_user => 'false',
                  username => 'i401',
                  channel => $channel,
                  text => $text});
} # send_notice

sub send_privmsg ($$$) {
  my ($self, $channel, $text) = @_;
  $text =~ s/\A[\x0D\x0A]+//;
  $text =~ s/[\x0D\x0A]+\z//;
  $self->{http}->request
      (method => 'POST',
       url => Web::URL->parse_string (q<https://slack.com/api/chat.postMessage>),
       params => {token => $self->config->{slack_token},
                  as_user => 'false',
                  username => $self->config->{nick},
                  channel => $channel,
                  text => $text});
} # send_privmsg

1;
