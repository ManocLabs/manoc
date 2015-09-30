#!/usr/bin/env bash

# Fail fast and fail hard.
set -eo pipefail

INSTALL_DIR="/opt/manoc"
PATH="$INSTALL_DIR/bin:$PATH"

yum install -y perl-core perl-DBD-MySQL net-snmp-perl libpcap-devel

export PERL5LIB="$INSTALL_DIR/perl5"
if ! [ -e "$INSTALL_DIR/bin/cpanm" ]; then
  echo "-----> Bootstrapping cpanm"
  curl -L --silent https://raw.github.com/miyagawa/cpanminus/master/cpanm | perl - App::cpanminus 2>&1 
fi

PERL_CPANM_OPT="--quiet --notest -l $INSTALL_DIR \
	--with-feature=mysql \
	--with-feature=arpsniffer  \
	--with-feature=snmp "
export PERL_CPANM_OPT

echo "-----> Installing dependencies"
echo "cpanm options: $PERL_CPANM_OPT"
cd /vagrant && cpanm --installdeps . 2>&1

