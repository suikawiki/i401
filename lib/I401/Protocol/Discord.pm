package I401::Protocol::Discord;
use strict;
use warnings;
use JSON::PS;
use Web::URL;
use Web::Transport::BasicClient;
use Web::Transport::WSClient;
use Promise;
use Promised::Flow;
use AbortController;

use I401::Fetch;

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
  my $url = Web::URL->parse_string (q<wss://gateway.discord.gg/>);

  my $ac0 = AbortController->new;
  return Promise->resolve->then (sub {
    my $seq = undef;

    return Web::Transport::WSClient->new (
      url => $url,
      params => {
        v => 10,
      },
      cb => sub {
        my ($client, $data, $is_text) = @_;
        return unless length $data;
        
        my $json = json_bytes2perl $data;
        my $op = $json->{op} // '';

        if ($op == 10) { # hello
          my $heartbeat_interval = $json->{d}->{heartbeat_interval} / 1000;
          $self->log ("Hello received");

          my $ac = AbortController->new;
          promised_sleep ($heartbeat_interval * rand 1, signal => $ac->signal)->then (sub {
            return promised_wait_until {
              $client->send_text (perl2json_chars {
                op => 1, # heartbeat
                d => $seq,
              });
              return not 'done';
            } interval => $heartbeat_interval, signal => $ac->signal;
          });

          $ac0->signal->manakai_onabort (sub {
            $ac->abort;
            $client->close;
          });

          $client->send_text (perl2json_chars {
            op => 2, # identify
            d => {
              token => $self->config->{discord_token},
              
              properties => {
                os => 'linux',
                browser => 'disco',
                device => 'disco',
              },
              intents =>
                  (1 << 0) | # GUILDS
                # (1 << 1) | # GUILD_MEMBERS
                  (1 << 9) | # GUILD_MESSAGES 
                  (1 << 10) | # GUILD_MESSAGE_REACTIONS
                  (1 << 15) # MESSAGE_CONTENT 
              ,
            },
          });
        } elsif ($op == 0) {
          if ($json->{t} eq 'MESSAGE_CREATE') {
            my $message = $json->{d};
            if (not $message->{author}->{id} eq $self->{user_id}) {
              $self->{i401}->process_by_rules({
                #prefix => $msg->{prefix},
                channel => $message->{channel_id},
                command => 'PRIVMSG',
                text => $message->{content},
                message => I401::Protocol::Discord::Message->wrap ($json->{d}, $self),
              });
            }
          } elsif ($json->{t} eq 'READY') {
            $self->{user_id} = $json->{d}->{user}->{id};
            $self->log ("READY received (my user ID: $self->{user_id})");
          } else {
            #warn "Data [$json->{t}] ($data)";
          }
        } elsif ($op == 9) {
          $self->log ("Invalid session ($data)", class => 'error');
          $ac0->abort;
        } elsif ($op == 11) {
          #warn "Heartbeat ack";
        } else {
          #warn $data;
        }
        
        $seq = $json->{s};
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

*send_notice = \&send_privmsg;
sub send_privmsg ($$$;%) {
  my ($self, $channel, $text, %args) = @_;
  $text =~ s/\A[\x0D\x0A]+//;
  $text =~ s/[\x0D\x0A]+\z//;

  my $params = {};
  $params->{content} = $text;
  #allowed_mentions => {"parse" => ["users"]},
  
  if (defined $args{in_reply_to}) {
    my $raw = $args{in_reply_to}->raw;
    $params->{message_reference}->{message_id} = $raw->{id};
  }

  return I401::Fetch->post_data
        (Web::URL->parse_string (q<https://discord.com/api/channels/>.$channel.q</messages>), $params,
         headers => {
           authorization => 'Bot ' . $self->config->{discord_token},
           'user-agent' => 'DiscordBot ($url, $versionNumber)',
         });
} # send_privmsg

package I401::Protocol::Discord::Message;
push our @ISA, qw(I401::Main::Message);

sub protocol ($) { 'Discord' }
sub myself ($) { $_[0]->{user_id} }

sub wrap ($$$) {
  my ($class, $raw, $con) = @_;
  return bless {
    raw => $raw,
    user_id => $con->{user_id},
    connection_name => $con->config->{name},
    id => (join '-',
           'Discord',
           $con->config->{name} // '',
           $raw->{guild_id},
           $raw->{channel_id},
           $raw->{id}),
  }, $class;
} # wrap

sub is_mentioned ($) {
  my $self = $_[0];
  return $self->{mentioned} if exists $self->{mentioned};

  for (@{$self->{raw}->{mentions} or []}) {
    if ($_->{id} eq $self->{user_id}) {
      return $self->{mentioned} = 1;
    }
  }

  return $self->{mentioned} = 0;
} # is_mentioned

1;

=head1 LICENSE

Copyright 2023 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
