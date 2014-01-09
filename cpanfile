
      use inc::Module::Install;
      name "Dummy";
      open my $file, "<", "config/perl/pmb-install.txt"
          or die "$0: config/perl/pmb-install.txt: $!";
      while (<$file>) {
        if (/^([0-9A-Za-z_:]+)/) {
          requires $1;
        }
      }
      Meta->write;
      Meta->write_mymeta_json;
    