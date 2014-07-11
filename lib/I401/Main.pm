package I401::Main;
use strict;
use warnings;
use Encode;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(decode_ctcp);
use AnyEvent::HTTPD;

sub new_from_config {
    return bless {config => $_[1]}, $_[0];
}

sub config {
    return $_[0]->{config};
}

sub client {
    my $self = $_[0];
    $self->{client} ||= do {
        my $client = AnyEvent::IRC::Client->new;
        my $config = $self->config;
        $client->enable_ssl if $config->{tls};

        $client->set_nick_change_cb(sub {
            my $nick = shift;
            if ($nick =~ /\A(.*[^0-9]|)401\z/s) {
                return $1.400;
            } elsif ($nick =~ /\A(.*[^0-9]|)([0-9]+)\z/s) {
                return $1.($2+1);
            } else {
                return $nick.2;
            }
        });

        $self->log('Connect...');
        $client->reg_cb(connect => sub {
            my ($client, $err) = @_;
            $self->log("Connected");
            die $err if defined $err;
        });
        $client->reg_cb(registered => sub {
            $self->log('Registered');
            $client->send_srv(JOIN => encode 'utf-8', $_)
                for @{$config->{default_channels} or []};
            $client->enable_ping (60);
        });

        $client->reg_cb(disconnect => sub {
            $self->log('Disconnected', class => 'error');
            undef $client;
            $self->reconnect;
        });

        $client->connect(
            scalar ($config->{hostname} || die "No |hostname|"),
            scalar ($config->{port} || 6667),
            {
                nick => ($config->{nick} || die "No |nick|"),
                real => $config->{real},
                user => $config->{user},
                password => $config->{password},
                timeout => 10,
            },
        );

        $self->{timer} = AE::timer 60, 0, sub {
            unless ($client and $client->registered) {
                $self->log("Timeout", class => 'error');
                $client->disconnect if $client;
                $self->reconnect;
            }
            undef $self->{timer};
        };

        $client->reg_cb(irc_invite => sub {
            my ($client, $msg) = @_;
            my $channel = $msg->{params}->[1]; # no decode
            $client->send_srv(JOIN => $channel); # no encode
        });

        $client->reg_cb(join => sub {
            my ($client, $nick, $channel, $is_myself) = @_;
            if ($is_myself) {
                $channel = decode 'utf-8', $channel;
                $self->log('Join ' . $channel);
                $self->{current_channels}->{$channel}++;
            }
        });

        $client->reg_cb(channel_remove => sub {
            my ($client, $msg, $channel, @nick) = @_;
            if (grep { $client->is_my_nick($_) } @nick) {
                $channel = decode 'utf-8', $channel;
                $self->log('Part ' . $channel);
                delete $self->{current_channels}->{$channel};
            }
        });

        $client->reg_cb(irc_privmsg => sub {
            my (undef, $msg) = @_;
            my ($trail, $ctcp) = decode_ctcp($msg->{params}->[-1]);
            my $channel = decode 'utf-8', $msg->{params}->[0];
            $msg->{params}->[-1] = $trail;

            if ($msg->{params}->[-1] ne '') {
                my $nick = [split /!/, $msg->{prefix}, 2]->[0];
                unless ($client->is_my_nick($nick)) {
                    my $charset = $self->get_channel_charset($channel);
                    my $text = decode $charset, $msg->{params}->[-1];
                    $self->process_by_rules({
                        prefix => $msg->{prefix},
                        channel => $channel,
                        command => $msg->{command},
                        text => $text,
                    });
                }
            }
        });
        $client->reg_cb(irc_notice => sub {
            my (undef, $msg) = @_;
            my ($trail, $ctcp) = decode_ctcp($msg->{params}->[-1]);
            my $channel = decode 'utf-8', $msg->{params}->[0];
            $msg->{params}->[-1] = $trail;

            if ($msg->{params}->[-1] ne '') {
                my $nick = [split /!/, $msg->{prefix}, 2]->[0];
                unless ($client->is_my_nick($nick)) {
                    my $charset = $self->get_channel_charset($channel);
                    my $text = decode $charset, $msg->{params}->[-1];
                    $self->process_by_rules({
                        prefix => $msg->{prefix},
                        channel => $channel,
                        command => $msg->{command},
                        text => $text,
                    });
                }
            }
        });

        $client;
    };
}

sub connect {
    my ($self) = @_;
    $self->client;
}

sub disconnect {
    my $self = shift;
    delete $self->{current_channels};
    $self->client->disconnect if $self->{client};
}

sub reconnect {
    my $self = shift;
    delete $self->{client};
    delete $self->{current_channels};
    my $timer; $timer = AE::timer 10, 0, sub {
        $self->connect;
        undef $timer;
    };
}

sub register_rules {
    my $self = shift;
    push @{$self->{rules} ||= []}, @_;
}

sub process_by_rules {
    my ($self, $args) = @_;
    for (@{$self->{rules} ||= []}) {
        if ($_->{privmsg} and $_->{notice}) {
            next unless $args->{command} eq 'PRIVMSG' or
                        $args->{command} eq 'NOTICE';
        } elsif ($_->{privmsg}) {
            next unless $args->{command} eq 'PRIVMSG';
        } elsif ($_->{notice}) {
            next unless $args->{command} eq 'NOTICE';
        }

        my $pattern = defined $_->{pattern} ? $_->{pattern} : qr/(?:)/;
        next unless $args->{text} =~ /$_->{pattern}/; # $1...

        $_->{code}->($self, $args);
    }
}

sub get_channel_charset {
    my ($self, $channel) = @_;
    return $self->config->{channel_charset}->{$channel} ||
           $self->config->{charset} ||
           'utf-8';
}

sub get_channel_users {
    my ($self, $channel) = @_;
    my $client = $self->client;
    my $user_mode = ($client->{channel_list}->{encode 'utf-8', $client->lower_case($channel)} || {});
    return [ grep { not $client->is_my_nick($_) } keys %$user_mode ];
}

sub send_notice ($$$) {
  my ($self, $channel, $text) = @_;
  $text =~ s/\A[\x0D\x0A]+//;
  $text =~ s/[\x0D\x0A]+\z//;
  for my $text (split /\x0D?\x0A/, $text) {
    $self->client->send_srv(JOIN => encode 'utf-8', $channel)
        unless $self->{current_channels}->{$channel};
    my $charset = $self->get_channel_charset($channel);
    my $max = $self->config->{max_length} || 200;
      while (length $text) {
        my $t = substr ($text, 0, $max);
        substr ($text, 0, $max) = '';
        $self->client->send_srv('NOTICE',
                                (encode 'utf-8', $channel),
                                (encode $charset, $t));
      }
  }
} # send_notice

sub send_privmsg ($$$) {
  my ($self, $channel, $text) = @_;
  $text =~ s/\A[\x0D\x0A]+//;
  $text =~ s/[\x0D\x0A]+\z//;
  for my $text (split /\x0D?\x0A/, $text) {
    $self->client->send_srv(JOIN => encode 'utf-8', $channel)
        unless $self->{current_channels}->{$channel};
    my $charset = $self->get_channel_charset($channel);
    my $max = $self->config->{max_length} || 200;
    while (length $text) {
      my $t = substr ($text, 0, $max);
      substr ($text, 0, $max) = '';
      $self->client->send_srv('PRIVMSG',
                              (encode 'utf-8', $channel),
                              (encode $charset, $t));
    }
  }
} # send_privmsg

sub listen {
    my $self = shift;
    return unless $self->config->{http_port};

    $self->{httpd} = AnyEvent::HTTPD->new (
        hostname => $self->config->{http_hostname},
        port => $self->config->{http_port},
    );
    $self->log(sprintf 'Listening %s:%d...',
                   $self->config->{http_hostname},
                   $self->config->{http_port});

    $self->{httpd}->reg_cb (
        '' => sub {
            my ($httpd, $req) = @_;
            $self->log(sprintf '%s %s %s', $req->client_host, $req->method, $req->url);
            my $path = $req->url->path;
            unless ($path =~ m{\A/(notice|privmsg)\z}) {
                return $req->respond([400, 'Not found', {}, '404 Not found']);
            }
            my $method = 'send_' . $1;
            my $command = uc $1;

            return $req->respond([405, 'Method not allowed', {Allow => 'POST'},
                                  '405 Method not allowed'])
                unless $req->method eq 'POST';
            return $req->respond([400, 'Access from browser not allowed', {},
                                  '400 Access from browser not allowed'])
                if defined $req->headers->{origin};

            my $channel = $req->parm('channel');
            my $msg = $req->parm('message');
            my $apply_rules = $req->parm('rules');

            $req->respond([400, 'Bad channel', {}, '400 Bad channel'])
                unless defined $channel and length $channel;
            $req->respond([400, 'Bad message', {}, '400 Bad message'])
                unless defined $msg and length $msg;

            $channel = decode 'utf-8', $channel;
            $msg = decode 'utf-8', $msg;

            AE::postpone {
                $self->$method($channel, $msg);

                $self->process_by_rules({
                    prefix => '!',
                    channel => $channel,
                    command => (($apply_rules and $apply_rules eq 'PRIVMSG')
                                    ? 'PRIVMSG' : $command),
                    text => $msg,
                }) if $apply_rules;
            };
            $req->respond([202, 'Accepted', {}, '202 Accepted']);
        },
    );
}

sub run {
    my $self = shift;
    $self->connect;
    $self->listen;

    my $cv = AE::cv;

    $self->{sigterm} = AE::signal TERM => sub {
        $self->log('SIGTERM received', class => 'error');
        $self->disconnect;
        delete $self->{sigterm};
        delete $self->{sigint};
        AE::postpone { $cv->send };
    };
    $self->{sigint} = AE::signal INT => sub {
        $self->log('SIGINT received', class => 'error');
        $self->disconnect;
        delete $self->{sigterm};
        delete $self->{sigint};
        AE::postpone { $cv->send };
    };

    $cv->recv;
}

sub stderr {
    return $_[0]->{stderr} ||= do {
        my $handle = AnyEvent::Handle->new(
            fh => \*STDERR,
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                AE::log error => $msg;
                $hdl->destroy;
                #$cv->send;
            },
        );
        $handle;
    };
}

sub log {
    my ($self, $text, %args) = @_;
    $self->stderr->push_write(encode 'utf-8', ('[' . (gmtime) . '] ' . $text . "\n"));
}

1;
