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

( cd /vagrant && cpanm --installdeps . 2>&1 )


echo "-----> Installing MIBS"
MIBS_DIR="$INSTALL_DIR/netdisco-mibs"
MIBS_TAR="$INSTALL_DIR/mibs.tar.gz"
if ! [ -f "$MIBS_TAR" ]; then
  NETDISCO_MIBS_URL="http://downloads.sourceforge.net/project/netdisco/netdisco-mibs/latest-snapshot/netdisco-mibs-snapshot.tar.gz"
  curl -L "$NETDISCO_MIBS_URL" > "$MIBS_TAR"
fi
( cd "$INSTALL_DIR" && tar -xzf "$MIBS_TAR" )
test -d /etc/snmp || mkdir -p /etc/snmp
perl -ne "s|/usr/local/netdisco/mibs|$MIBS_DIR|; if ( /^mibdirs/ ) { /cisco|rfc|net-snmp/ and print } else { print }" "$MIBS_DIR/snmp.conf"> /etc/snmp/snmp.conf
echo "Done"

echo "-----> Setting firewall"
firewall-cmd --get-default-zone | grep trusted || 
	firewall-cmd --set-default-zone trusted
echo "Done"
