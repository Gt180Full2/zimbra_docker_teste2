#!/bin/sh
## Preparing all the variables like IP, Hostname, etc, all of them from the container
sleep 5
HOSTNAME=$(hostname -s)
DOMAIN=$(hostname -d)
CONTAINERIP=$(ifconfig |grep -A1 eth0 |grep inet|awk '{print $2}')
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)

## Configurando servidor sshd ##
echo "Configurando o servidor sshd."
/usr/bin/ssh-keygen -A
/sbin/sshd -D &

#Testando esse aqui!
## Installing the DNS Server ##
echo "Configuring DNS Server"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.old
cat <<EOF >>/etc/dnsmasq.conf
server=187.18.5.7
server=187.18.5.8
server=8.8.8.8
listen-address=127.0.0.1
domain=$DOMAIN
mx-host=$DOMAIN,$HOSTNAME.$DOMAIN,0
address=/$HOSTNAME.$DOMAIN/$CONTAINERIP
EOF

##Iniciando DNS Masq
/usr/sbin/dnsmasq -D &

## Creating the Zimbra Collaboration Config File ##
touch /opt/zimbra-install/installZimbraScript
cat <<EOF >/opt/zimbra-install/installZimbraScript
AVDOMAIN="$DOMAIN"
AVUSER="admin@$DOMAIN"
CREATEADMIN="admin@$DOMAIN"
CREATEADMINPASS="$PASSWORD"
CREATEDOMAIN="$DOMAIN"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$HOSTNAME.$DOMAIN"
HTTPPORT="80"
HTTPPROXY="TRUE"
HTTPPROXYPORT="8080"
HTTPSPORT="443"
HTTPSPROXYPORT="8443"
IMAPPORT="143"
IMAPPROXYPORT="7143"
IMAPSSLPORT="993"
IMAPSSLPROXYPORT="7993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="$PASSWORD"
LDAPPOSTPASS="$PASSWORD"
LDAPROOTPASS="$PASSWORD"
LDAPADMINPASS="$PASSWORD"
LDAPREPPASS="$PASSWORD"
LDAPBESSEARCHSET="set"
LDAPDEFAULTSLOADED="1"
LDAPHOST="$HOSTNAME.$DOMAIN"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="redirect"
MYSQLMEMORYPERCENT="30"
POPPORT="110"
POPPROXYPORT="7110"
POPSSLPORT="995"
POPSSLPROXYPORT="7995"
PROXYMODE="redirect"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="no"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$DOMAIN"
SMTPHOST="$HOSTNAME.$DOMAIN"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$DOMAIN"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$HOSTNAME.$DOMAIN"
SPELLURL="http://$HOSTNAME.$DOMAIN:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$DOMAIN"
TRAINSASPAM="spam.$RANDOMSPAM@$DOMAIN"
UIWEBAPPS="yes"
UPGRADE="yes"
USEKBSHORTCUTS="TRUE"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$DOMAIN"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$PASSWORD"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$PASSWORD"
ldap_url="ldap://$HOSTNAME.$DOMAIN:389"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$PASSWORD"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/lib/jvm/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP=""
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraDefaultDomainName="$DOMAIN"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $CONTAINERIP/32 [::1]/128"
zimbraPrefTimeZoneId="America/Bahia"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@$DOMAIN"
zimbraVersionCheckNotificationEmailFrom="admin@$DOMAIN"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="$HOSTNAME.$DOMAIN"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF

##Install the Zimbra Collaboration ##

echo "Downloading Zimbra Collaboration 8.8.15"
wget -O /opt/zimbra-install/zimbra.tar.gz https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz

echo "Extracting files from the archive"
tar xzvf /opt/zimbra-install/zimbra.tar.gz -C /opt/zimbra-install/

echo "Installing Zimbra Collaboration just the Software"
cd /opt/zimbra-install/zcs-* && ./install.sh -s < /opt/zimbra-install/installZimbra-keystrokes

# Work around install issues.
mkdir -p /opt/zimbra/common/lib/jvm/java/jre/lib/security
chown -R zimbra:zimbra /opt/zimbra/common/lib/jvm/java/jre/lib/security

echo "Installing Zimbra Collaboration injecting the configuration"
/opt/zimbra/libexec/zmsetup.pl -c /opt/zimbra-install/installZimbraScript

echo "Adding ZetAlliance Repository"
wget https://copr.fedorainfracloud.org/coprs/zetalliance/zimlets/repo/epel-7/zetalliance-zimlets-epel-7.repo -O /etc/yum.repos.d/zetalliance-zimlets-epel-7.repo

echo "Installing zimbra-patch"
yum clean metadata
yum check-update
yum install zimbra-patch -y

echo "Restarting Zimbra"
su - zimbra -c 'zmcontrol restart'

echo "yum clean all"
yum clean all

echo "Replacing Installer Script with Start Script"
mv /opt/start.sh /opt/start.sh_installer && mv /opt/start.sh_postinstall /opt/start.sh

echo "Removing Install Files"
cd ~
rm -rf /opt/zimbra-install

echo "Execultando Rsyslogd pro Zimbra"
/opt/zimbra/libexec/zmsyslogsetup -D &

##Iniciando o rsyslogd
/usr/sbin/rsyslogd -D &

echo "Restarting Zimbra 2"
su - zimbra -c 'zmcontrol restart'

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
