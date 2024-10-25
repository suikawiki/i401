package I401::Protocol::Chatwork;
use strict;
use warnings;
use Web::URL;
use Web::Transport::BasicClient;
use JSON::PS;

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

  $self->{client} = Web::Transport::BasicClient->new_from_url
      (Web::URL->parse_string (q<https://api.chatwork.com/v2/>));

  ## <https://developer.chatwork.com/reference/get-me>
  $self->{client}->request (
    method => 'GET',
    path => ['me'],
    headers => {
      'x-chatworktoken' => $self->config->{chatwork_token},
    },
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;

    my $json = json_bytes2perl $res->body_bytes;
    die "Failed to get accoount data" unless defined $json and
        ref $json eq 'HASH' and
        defined $json->{account_id};

    $self->{user_id} = $json->{account_id};
  });
  
  return undef;
} # connect

sub set_shutdown_mode ($$) {
  $_[0]->{shutdown} = 1;
  $_[0]->{onshutdown} = $_[1];
} # set_shutdown_mode

sub disconnect ($) {
  my $self = shift;
  if ($self->{shutdown}) {
    (delete $self->{onshutdown})->() if $self->{onshutdown};
  }
  return $self->{client}->close if defined $self->{client};
} # disconnect

sub reconnect ($) {
  #
} # reconnect

sub handle_webhook ($$%) {
  my ($self, $json, %args) = @_;
  #$args{signature}

  ## <https://developer.chatwork.com/docs/webhook>
  return unless defined $json and ref $json eq 'HASH';
  return unless defined $json->{webhook_event} and
      ref $json->{webhook_event} eq 'HASH';
  my $type = $json->{webhook_event_type} // '';
  if ($type eq 'message_created' or $type eq 'mention_to_me') {
    $self->{i401}->process_by_rules ({
      #prefix => $msg->{prefix},
      channel => $json->{webhook_event}->{room_id},
      command => 'PRIVMSG',
      #text => $json->{text},
      message => I401::Protocol::Chatwork::Message->wrap ($json, $self),
    });
  } elsif ($type eq 'message_updated') {
    #
  } else { # unknown
    #
  }
} # handle_webhook

sub send_notice ($$$) {
  my ($self, $channel, $text) = @_;
  #          ^ room_id
  
  ## <https://developer.chatwork.com/reference/post-rooms-room_id-messages>
  return $self->{client}->request (
    method => 'POST',
    path => ['rooms', $channel, 'messages'],
    headers => {
      'x-chatworktoken' => $self->config->{chatwork_token},
    },
    params => {
      body => $text,
    },
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
  });
} # send_notice
*send_privmsg = \&send_notice;

package I401::Protocol::Chatwork::Message;
push our @ISA, qw(I401::Main::Message);

sub protocol ($) { 'Chatwork' }
sub myself ($) { $_[0]->{user_id} }

sub wrap ($$$) {
  my ($class, $raw, $con) = @_;
  return bless {
    raw => $raw,
    user_id => $con->{user_id},
    connection_name => $con->config->{name},
    id => (join '-',
           'Chatwork',
           $con->config->{name} // '',
           $raw->{webhook_event_time} || 0,
           $raw->{webhook_event_type} // '',
           $raw->{webhook_event}->{message_id} // '',
           $raw->{webhook_event}->{update_time} || 0),
  }, $class;
} # wrap

sub is_mentioned ($) {
  my $self = $_[0];
  return (
    $self->{raw}->{webhook_event_type} eq 'mention_to_me'
  );
} # is_mentioned

#is_bot

1;

=head1 LICENSE

Copyright 2024 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
