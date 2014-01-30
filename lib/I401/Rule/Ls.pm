package I401::Rule::Ls;
use strict;
use warnings;
use utf8;
use Time::Local qw(timelocal_nocheck);

sub sl ();

sub get {
    return ({
        privmsg => 1,
        pattern => qr{^ls$},
        code => sub {
            my ($irc, $args) = @_;
            $irc->send_notice($args->{channel}, scalar `ls`);
        },
    }, {
        privmsg => 1,
        pattern => qr{^sl$},
        code => sub {
            my ($irc, $args) = @_;
            $irc->send_notice($args->{channel}, sl);
        },
    });
}

## <https://github.com/mtoyoda/sl>
##
## Copyright 1993,1998,2013 Toyoda Masashi (mtoyoda@acm.org)
##
## Everyone is permitted to do anything on this program including copying,
## modifying, and improving, unless you try to pretend that you wrote it.
## i.e., the above copyright notice has to appear in all copies.
## THE AUTHOR DISCLAIMS ANY RESPONSIBILITY WITH REGARD TO THIS SOFTWARE.
sub sl { q{      ++      +------ ____                 ____________________ ____________________
      ||      |+-+ |  |   \@@@@@@@@@@@     |  ___ ___ ___ ___ | |  ___ ___ ___ ___ |
    /---------|| | |  |    \@@@@@@@@@@@@@_ |  |_| |_| |_| |_| | |  |_| |_| |_| |_| |
   + ========  +-+ |  |                  | |__________________| |__________________|
  _|--/~\------/~\-+  |__________________| |__________________| |__________________|
 //// \O========O/       (O)       (O)        (O)        (O)       (O)        (O)
} }

1;
