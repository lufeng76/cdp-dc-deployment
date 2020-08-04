# Define global variables here
export BUILD_NUMBER=3274282
export USER=frisch
export PRINCIPAL=frisch
export REALM=FRISCH.COM
export HOSTNAME=fri2-

## On ALL nodes

# Setup cloudera manager repo
echo "[cloudera-manager]
name=Cloudera Manager 7.1.1
baseurl=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/
gpgkey=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera
gpgcheck=1
enabled=1
autorefresh=0
type=rpm-md" >> /etc/yum.repos.d/cloudera-manager-7_1-${BUILD_NUMBER}.repo
rpm --import https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Download KRB libs
yum install -y krb5-workstation krb5-libs

# System Pre-Requisites
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
systemctl start ntpd
echo "fs.file-max = 64000" >> /etc/sysctl.conf
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
echo 0 > /proc/sys/vm/swappiness
echo "vm.dirty_background_ratio=20
vm.dirty_ratio=50" >> /etc/sysctl.conf
# echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# User creation
useradd admin
useradd ${USER}

# Install Java & PostgreSQL connector
yum -y install java-1.8.0-openjdk-devel
yum -y install postgresql-jdbc*
cp /usr/share/java/postgresql-jdbc.jar /usr/share/java/postgresql-connector-java.jar
chmod 644 /usr/share/java/postgresql-connector-java.jar

#Install PostgresSQL client libs
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install https://yum.postgresql.org/10/redhat/rhel-7-x86_64/python3-psycopg2-2.8.5-1.rhel7.x86_64.rpm 
yum -y install postgresql10

# Create Kudus directories
mkdir -p /data/kudu 
chmod 755 /data/kudu 
chown kudu:kudu /data/kudu 

mkdir -p /tmp/kudu 
chmod 755 /tmp/kudu 
chown kudu:kudu /tmp/kudu 


# Generate Keys and Certificates Signing Requests  
# TODO : Make auto-signed certificates 
# Only on one node (CM one by default)
mkdir -p /opt/cloudera/security/pki/
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt
keytool -importcert -alias rootca -keystore /opt/cloudera/security/pki/truststore.jks -file /opt/cloudera/security/pki/rootCA.crt
chmod 444 /opt/cloudera/security/pki/rootCA.crt
chmod 400 /opt/cloudera/security/pki/rootCA.key

#Copy the rootCA.crt & rootCA.key & truststore.jks to all nodes and play these lines:
mkdir -p /opt/cloudera/security/pki/
cp ~/rootCA.* /opt/cloudera/security/pki/

keytool -genkeypair -alias $(hostname -f) -keyalg RSA -keystore /opt/cloudera/security/pki/$(hostname -f).jks -keysize 2048 -dname "CN=$(hostname -f)" -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera
keytool -certreq -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).csr -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera
openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -days 500 -sha256 -in /opt/cloudera/security/pki/$(hostname -f).csr -out /opt/cloudera/security/pki/$(hostname -f).crt
cat /opt/cloudera/security/pki/rootCA.crt >> /opt/cloudera/security/pki/$(hostname -f).crt
keytool -importcert -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).crt  -storepass cloudera

keytool -importkeystore -srckeystore /opt/cloudera/security/pki/$(hostname -f).jks -destkeystore /opt/cloudera/security/pki/$(hostname -f).p12 -srcalias $(hostname -f) -srcstoretype jks -deststoretype pkcs12  -storepass cloudera
openssl pkcs12 -in /opt/cloudera/security/pki/$(hostname -f).p12 -out /opt/cloudera/security/pki/$(hostname -f).pem

ln -s /opt/cloudera/security/pki/$(hostname -f).jks /opt/cloudera/security/pki/keystore.jks 
ln -s /opt/cloudera/security/pki/$(hostname -f).pem /opt/cloudera/security/pki/key.pem

chmod 444 /opt/cloudera/security/pki/*
chmod 400 /opt/cloudera/security/pki/rootCA.*

## Only on CM node 

export BUILD_NUMBER=2535749
export USER=frisch
export PRINCIPAL=frisch
export REALM=FRISCH.COM

# Install PostgreSQL 10
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install postgresql10-server postgresql10
/usr/pgsql-10/bin/postgresql-10-setup initdb
systemctl enable postgresql-10
systemctl start postgresql-10
yum -y install pip
pip install psycopg2==2.7.5 --ignore-installed
echo "listen_addresses = '*'
max_connections = 1000" >> /var/lib/pgsql/10/data/postgresql.conf
echo "
local   all             posgtres                                trust
host    all             all             0.0.0.0/0               md5
local   all             all                                     md5
" >> /var/lib/pgsql/10/data/pg_hba.conf

echo "CREATE ROLE scm LOGIN PASSWORD 'admin';
    CREATE DATABASE scm OWNER scm ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE amon LOGIN PASSWORD 'admin';
    CREATE DATABASE amon OWNER amon ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE rman LOGIN PASSWORD 'admin';
    CREATE DATABASE rman OWNER rman ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE hue LOGIN PASSWORD 'admin';
    CREATE DATABASE hue OWNER hue ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE hive LOGIN PASSWORD 'admin';
    CREATE DATABASE metastore OWNER hive ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE oozie LOGIN PASSWORD 'admin';
    CREATE DATABASE oozie OWNER oozie ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE das LOGIN PASSWORD 'admin';
    CREATE DATABASE das OWNER das ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE smm LOGIN PASSWORD 'admin';
    CREATE DATABASE smm OWNER smm ENCODING 'UTF8' TEMPLATE template0;
    CREATE ROLE rangeradmin LOGIN PASSWORD 'admin';
    CREATE DATABASE ranger OWNER rangeradmin ENCODING 'UTF8' TEMPLATE template0;" > database_creation.sql
psql -U postgres -a -f database_creation.sql

# Install CM & start it
yum -y install cloudera-manager-agent cloudera-manager-daemons
yum -y install cloudera-manager-server
/opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm admin
systemctl start cloudera-scm-agent
systemctl enable cloudera-scm-agent
systemctl enable cloudera-scm-server
systemctl start cloudera-scm-server
sleep 60


# Install MIT-KDC
yum -y install krb5-server krb5-libs
echo "*/admin@${REALM}	 * " > /var/kerberos/krb5kdc/kadm5.acl
echo "
defaul_realm=${REALM}

[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 ${REALM} = { 
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  max_life = 24h 0m 0s
  max_renewable_life = 7d 0h 0m 0s
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }" > /var/kerberos/krb5kdc/kdc.conf

 echo "
 # Configuration snippets may be placed in this directory as well
includedir /etc/krb5.conf.d/

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 default_realm = ${REALM}
 default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

[realms]
${REALM} = {
  kdc = $(hostname -f):88
  admin_server = $(hostname -f):749
  default_domain = ${REALM,,}
}

[domain_realm]
  ${REALM,,} = ${REALM}
  .${REALM,,} = ${REALM}
" > /etc/krb5.conf

###### ATTENTION: This requires interaction from the user
kdb5_util create -r FRISCH.COM -s

systemctl start krb5kdc.service
systemctl start kadmin.service
systemctl enable krb5kdc.service
systemctl enable kadmin.service

###### ATTENTION: This requires interaction from the user
kadmin.local
addprinc admin/admin
addprinc ${USER}/admin
ktadd -k /home/${USER}/${USER}.keytab ${USER}/admin@FRISCH.COM


# Install and configure HA proxy required by HUE, OOZIE & IMPALA
yum -y install haproxy
cp /etc/haproxy/haproxy.cfg haproxy.cfg

echo "    
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen stats :25002
    balance
    mode http
    stats enable
    stats auth admin:admin

listen oozie :11003
    balance roundrobin
    mode tcp
    server  oozie1 cdp-test-1.gce.cloudera.com:11000 check
    server  oozie2 cdp-test-2.gce.cloudera.com:11000 check

listen oozie_https :11446
    balance roundrobin
    mode tcp
    server  oozie1 cdp-test-1.gce.cloudera.com:11443 check
    server  oozie2 cdp-test-2.gce.cloudera.com:11443 check
    " > haproxy.cfg

 echo 
 "listen impala :21001
    balance leastconn
    mode tcp
    server  impala1 cdp-test-4.gce.cloudera.com:21000 check
    server  impala2 cdp-test-5.gce.cloudera.com:21000 check
    server  impala3 cdp-test-6.gce.cloudera.com:21000 check

listen impalajdbc :21051
    balance leastconn
    mode tcp
    server  impala1 cdp-test-4.gce.cloudera.com:21051 check
    server  impala2 cdp-test-5.gce.cloudera.com:21051 check
    server  impala3 cdp-test-6.gce.cloudera.com:21051 check
    " >> haproxy.cfg   

/usr/sbin/haproxy -f haproxy.cfg 









