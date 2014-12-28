all:

clean: clean-json-ps clean-webua-oauth clean-kyuureki

WGET = wget
CURL = curl
GIT = git

updatenightly: local/bin/pmbp.pl
	#$(CURL) https://gist.githubusercontent.com/motemen/667573/raw/git-submodule-track | sh
	#$(GIT) add modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: git-submodules pmbp-install json-ps webua-oauth kyuureki

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

json-ps: local/perl-latest/pm/lib/perl5/JSON/PS.pm
clean-json-ps:
	rm -fr local/perl-latest/pm/lib/perl5/JSON/PS.pm
local/perl-latest/pm/lib/perl5/JSON/PS.pm:
	mkdir -p local/perl-latest/pm/lib/perl5/JSON
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-json-ps/master/lib/JSON/PS.pm

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
	perl local/bin/pmbp.pl --install-module Digest::SHA

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	$(PROVE) t/*.t
