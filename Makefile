all:

clean: clean-webua-oauth clean-kyuureki

WGET = wget
CURL = curl
GIT = git
PERL = ./perl

updatenightly: local/bin/pmbp.pl
	#$(CURL) https://gist.githubusercontent.com/motemen/667573/raw/git-submodule-track | sh
	$(GIT) add modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

## ------ Setup ------

deps: git-submodules pmbp-install webua-oauth kyuureki
deps-docker:         pmbp-install webua-oauth kyuureki

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update \
	    --write-makefile-pl cpanfile
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install

kyuureki: local/perl-latest/pm/lib/perl5/Kyuureki.pm
clean-kyuureki:
	rm -fr local/perl-latest/pm/lib/perl5/Kyuureki.pm
local/perl-latest/pm/lib/perl5/Kyuureki.pm:
	mkdir -p local/perl-latest/pm/lib/perl5
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-kyuureki/master/lib/Kyuureki.pm

webua-oauth: local/perl-latest/pm/lib/perl5/Web/UserAgent/OAuth.pm
clean-webua-oauth:
	rm -fr local/perl-latest/pm/lib/perl5/Web/UserAgent/OAuth.pm
local/perl-latest/pm/lib/perl5/Web/UserAgent/OAuth.pm: local/bin/pmbp.pl
	mkdir -p local/perl-latest/pm/lib/perl5/Web/UserAgent
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-web-useragent-functions/master/lib/Web/UserAgent/OAuth.pm
	$(PERL) local/bin/pmbp.pl --install-module Digest::SHA

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	$(PROVE) t/*.t
