#!/usr/bin/env bash

# Fail fast and fail hard.
set -eo pipefail

MANOC_DIR="/vagrant"
INSTALL_DIR="/opt/manoc"
PATH="$INSTALL_DIR/bin:/usr/local/bin:$PATH"

yum install -y perl-core perl-DBD-MySQL net-snmp-perl libpcap-devel

test -d "$INSTALL_DIR" || mkdir -p "$INSTALL_DIR"

export PERL5LIB="$INSTALL_DIR/perl5"
if ! [ -e /usr/local/bin/cpanm ]; then
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

( cd "$MANOC_DIR" && cpanm --installdeps . 2>&1 )

echo "-----> Installing devel modules"
cpanm Catalyst::Devel

echo "-----> Installing MIBS"
MIBS_DIR="$INSTALL_DIR/netdisco-mibs"
MIBS_TAR="$INSTALL_DIR/mibs.tar.gz"
if ! [ -f "$MIBS_TAR" ]; then
  NETDISCO_MIBS_URL="http://downloads.sourceforge.net/project/netdisco/netdisco-mibs/latest-snapshot/netdisco-mibs-snapshot.tar.gz"
  curl -L "$NETDISCO_MIBS_URL" > "$MIBS_TAR"
fi
( cd "$INSTALL_DIR" && tar -xzf "$MIBS_TAR" )
test -d /etc/snmp || mkdir -p /etc/snmp
perl -ne "s|/usr/local/netdisco/mibs|$MIBS_DIR|; if ( /^mibdirs/ ) { /cisco|rfc|net-snmp/ or print '# '; print; } else { print }" "$MIBS_DIR/snmp.conf"> /etc/snmp/snmp.conf
echo "Done"

echo "-----> Setting firewall"
if firewall-cmd --state; then
   firewall-cmd --get-default-zone | grep trusted ||
	firewall-cmd --set-default-zone trusted
fi
echo "Done"

echo "-----> Setting profile"
MANOC_SH_PROFILE=/etc/profile.d/manoc.sh
MANOC_DB=manocdb
cat <<EOF >$MANOC_SH_PROFILE
eval \$(perl -Mlocal::lib=$INSTALL_DIR)
export MANOC_DB_DSN="dbi:mysql:database=$MANOC_DB"
export MANOC_DB_USERNAME=manoc_rw_user
export MANOC_DB_PASSWORD=manoc123
EOF
. $MANOC_SH_PROFILE

echo "-----> Setting MariaDB"
yum install -y mariadb mariadb-server
systemctl enable mariadb
systemctl start mariadb
if ! echo 'SHOW DATABASES'|mysql|grep $MANOC_DB>/dev/null; then
  mysqladmin create $MANOC_DB
fi
echo "GRANT ALL ON ${MANOC_DB}.* TO '${MANOC_DB_USERNAME}'@'localhost' IDENTIFIED BY '${MANOC_DB_PASSWORD}'" | mysql
