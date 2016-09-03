package I401::Main;
use strict;
use warnings;
use I401::Main::Base;
push our @ISA, qw(I401::Main::Base);
use I401::Protocol::IRC;

sub _set_protocol ($) {
  my ($self) = @_;
  return $self->{protocol} = I401::Protocol::IRC->new_from_i401_and_config_and_logger
      ($self, $self->config, $self->logger);
} # _set_protocol

1;
