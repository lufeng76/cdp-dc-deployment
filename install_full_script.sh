##################################################################################
# Part01: System checks
# Note: The following script run on ALL NODES !!!
##################################################################################
# Define global variables here
export IP_ADDRESS=10.96.9.38
set -e

# System Pre-Requisites
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
getenforce

systemctl disable firewalld
systemctl stop firewalld
systemctl status firewalld

yum -y remove chrony
yum -y install ntp
systemctl start ntpd
systemctl status ntpd
ntpq -p

ulimit -Sn
ulimit -Hn
echo "fs.file-max = 64000" >> /etc/sysctl.conf
cat /proc/mounts
umask

sysctl -a | grep vm.swappiness
echo 1 > /proc/sys/vm/swappiness
sysctl vm.swappiness=1

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local

cat - > /etc/yum.repos.d/local_os.repo << EOF
[osrepo]
name=os_repo
baseurl=http://${IP_ADDRESS}/iso/
enabled=true
gpgcheck=false
EOF

cat - > /etc/yum.repos.d/local_cm.repo << EOF
[cloudera-manager]
name=cm_repo
baseurl=http://${IP_ADDRESS}/cm7.1/
enabled=true
gpgcheck=false
EOF

cat - > /etc/yum.repos.d/local_pg.repo << EOF
[postgresql-10]
name=pg_repo
baseurl=http://${IP_ADDRESS}/postgresql-10/
enabled=true
gpgcheck=false
EOF

# For YCloud only
echo "vm.dirty_background_ratio=20" >> /etc/sysctl.conf
echo "vm.dirty_ratio=50" >> /etc/sysctl.conf
# echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# Setup cloudera manager repo
cat - > /etc/yum.repos.d/cloudera-manager-7_1_1.repo << EOF
[cloudera-manager]
name=Cloudera Manager 7.1.1
baseurl=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/
gpgkey=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera
gpgcheck=1
enabled=1
autorefresh=0
type=rpm-md
EOF
rpm --import https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera

##################################################################################
# Part02: Pre-Installation
# Note: The following script run on ALL NODES !!!
##################################################################################

set -e
# Install Java & PostgreSQL connector
yum -y install openjdk8-8.0+232_9-cloudera
yum -y install postgresql-jdbc*
cp /usr/share/java/postgresql-jdbc.jar /usr/share/java/postgresql-connector-java.jar
chmod 644 /usr/share/java/postgresql-connector-java.jar

#Install PostgresSQL client libs
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install https://yum.postgresql.org/10/redhat/rhel-7-x86_64/python3-psycopg2-2.8.5-1.rhel7.x86_64.rpm 
yum -y install postgresql10

##################################################################################
# Part02: Pre-Installation
# Note: The following script only run on CM NODE !!!
##################################################################################

set -e
# Install PostgreSQL 10
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install postgresql10-server
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

sudo -u postgres psql << EOF
    CREATE ROLE scm LOGIN PASSWORD 'admin';
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
    CREATE DATABASE ranger OWNER rangeradmin ENCODING 'UTF8' TEMPLATE template0;
EOF

systemctl restart postgresql-10

##################################################################################
# Part03: CM installation
# Note: The following script only run on CM NODE !!!
##################################################################################

set -e
# Install CM & start it
yum -y install cloudera-manager-agent cloudera-manager-daemons
yum -y install cloudera-manager-server
/opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm admin
systemctl start cloudera-scm-agent
systemctl enable cloudera-scm-agent
systemctl enable cloudera-scm-server
systemctl start cloudera-scm-server
while [ -z `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version`] ;
    do
    echo "waiting 10s for CM Server to come up..";
    sleep 10;
done
echo "-- Now CM Server is started --"

##################################################################################
# Part04: CDP_Installation
# Note: No scripts, all done on CM homepage!
##################################################################################

##################################################################################
# Part05: Add_other_services
# Note: No scripts, all done on CM homepage!
##################################################################################

##################################################################################
# Part06: Enable_HA
# Note: The following script only run on CM NODE !!!
##################################################################################

set -e
# Install and configure HA proxy required by HUE, OOZIE & IMPALA
yum -y install haproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

cat - > /etc/haproxy/haproxy.cfg << EOF
global    
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    #stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    #option http-server-close
    #option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout connect         5000
    timeout client          3600s
    timeout server          3600s
    maxconn                 3000

listen stats
    bind 0.0.0.0:1080
    mode http
    option httplog
    maxconn 5000
    stats enable
    stats auth admin:admin
    stats refresh 30s
    stats  uri /stats

listen oozie_http
    bind 0.0.0.0:11003
    balance roundrobin
    mode tcp
    option tcplog
    server  oozie1 ccycloud-1.feng.root.hwx.site:11000 check
    server  oozie2 ccycloud-2.feng.root.hwx.site:11000 check

listen oozie_https
    bind 0.0.0.0:11446
    balance roundrobin
    mode tcp
    option tcplog
    server  oozie1 ccycloud-1.feng.root.hwx.site:11443 check
    server  oozie2 ccycloud-2.feng.root.hwx.site:11443 check

listen impalashell
    bind 0.0.0.0:21001
    balance leastconn
    mode tcp
    option tcplog
    server  impala1 ccycloud-3.feng.root.hwx.site:21000 check
    server  impala2 ccycloud-4.feng.root.hwx.site:21000 check
    server  impala3 ccycloud-5.feng.root.hwx.site:21000 check

listen impalajdbc 
    bind 0.0.0.0:21051
    balance leastconn
    mode tcp
    option tcplog
    server  impala1 ccycloud-3.feng.root.hwx.site:21050 check
    server  impala2 ccycloud-4.feng.root.hwx.site:21050 check
    server  impala3 ccycloud-5.feng.root.hwx.site:21050 check
    
listen hivejdbc
    bind 0.0.0.0:10099
    balance source
    mode tcp
    option tcplog
    server hive1 ccycloud-1.feng.root.hwx.site:10000 check
    server hive2 ccycloud-2.feng.root.hwx.site:10000 check    
EOF

systemctl enable haproxy
systemctl start haproxy

##################################################################################
# Part07: Cluster_validation
# Note: The following script run on ALL NODES !!!
##################################################################################

echo "create user etl_user"
groupadd etl
useradd -g etl etl_user
echo BadPass#1 > passwd.txt
echo BadPass#1 >> passwd.txt
passwd etl_user < passwd.txt
rm -f passwd.txt

##################################################################################
# Part07: Cluster_validation
# Note: The following script only run on CM NODE !!!
##################################################################################

echo "create hdfs dir for user etl_user"
sudo -u hdfs hadoop fs -mkdir /user/etl_user
sudo -u hdfs hadoop fs -chown etl_user:hadoop /user/etl_user

##################################################################################
# Part08: Enable_Kerberos
# Note: The following script run on ALL NODES !!!
##################################################################################
# Install KDC client and libs
yum install -y krb5-workstation krb5-libs

# Define global variables here
export host=ccycloud-1.feng.root.hwx.site
export realm=FENG.COM
export domain=feng.com
sudo cat - > /etc/krb5.conf << EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = $realm
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
 default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
 permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5

[realms]
 $realm = {
  kdc = $host
  admin_server = $host
 }

[domain_realm]
 .$domain = $realm
 $domain = $realm
EOF

##################################################################################
# Part08: Enable_Kerberos
# Note: The following script only run on CM NODE !!!
##################################################################################

# Define global variables here
export host=ccycloud-1.feng.root.hwx.site
export realm=FENG.COM
export domain=feng.com
export kdcpassword=Admin1234

set -e

# Install MIT-KDC
sudo yum -y install krb5-server

mv /var/kerberos/krb5kdc/kdc.conf{,.original}
sudo cat - >  /var/kerberos/krb5kdc/kdc.conf << EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88
[realms]
 ${realm} = {
 acl_file = /var/kerberos/krb5kdc/kadm5.acl
 dict_file = /usr/share/dict/words
 admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
 supported_enctypes = aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal arcfour-hmac-md5:normal
 max_renewable_life = 7d
}
EOF

echo $kdcpassword > passwd
echo $kdcpassword >> passwd
sudo kdb5_util create -s < passwd

sudo systemctl start krb5kdc
sudo systemctl start kadmin
sudo systemctl enable krb5kdc
sudo systemctl enable kadmin

sudo kadmin.local -q "addprinc admin/admin" < passwd
sudo kadmin.local -q "addprinc cloudera-scm/admin" < passwd
rm -f passwd

sudo cat - > /var/kerberos/krb5kdc/kadm5.acl << EOF
*/admin@$realm  *
EOF

sudo systemctl restart krb5kdc
sudo systemctl restart kadmin

echo "Waiting to KDC to restart..."
sleep 5

sudo systemctl status krb5kdc
sudo systemctl status kadmin

kadmin.local -q "modprinc -maxrenewlife 7day krbtgt/${realm}@${realm}"

echo "For testing KDC run below:"
kadmin -p admin/admin -w $kdcpassword -r $realm -q "get_principal admin/admin"

kadmin -p cloudera-scm/admin -w $kdcpassword -r $realm -q "get_principal cloudera-scm/admin"

echo "KDC setup complete"

echo "create keytabs for user etl_user"
kadmin.local -q "addprinc -randkey etl_user/${host}@${realm}"
kadmin.local -q "xst -k etl_user.keytab etl_user/${host}@${realm}"
mkdir -p /etc/security/keytabs
mv etl_user.keytab /etc/security/keytabs

##################################################################################
# Part09: Ranger_Access_Policies
# Note: No scripts, all done on CM homepage!
##################################################################################


##################################################################################
# Part10: Encryption-CM
# Note: The following script only run on CM NODE !!!
##################################################################################
# Generate Keys and Certificates Signing Requests  
# TODO : Make auto-signed certificates 
# Only on one node (CM one by default)
mkdir -p /opt/cloudera/security/pki/
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt
keytool -importcert -alias rootca -keystore /opt/cloudera/security/pki/truststore.jks -file /opt/cloudera/security/pki/rootCA.crt

#Copy the rootCA.crt & rootCA.key & truststore.jks to all nodes
scp /opt/cloudera/security/pki/rootCA.* root@ccycloud-2.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/truststore.jks root@ccycloud-2.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/rootCA.* root@ccycloud-3.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/truststore.jks root@ccycloud-3.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/rootCA.* root@ccycloud-4.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/truststore.jks root@ccycloud-4.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/rootCA.* root@ccycloud-5.feng.root.hwx.site:/opt/cloudera/security/pki/
scp /opt/cloudera/security/pki/truststore.jks root@ccycloud-5.feng.root.hwx.site:/opt/cloudera/security/pki/

#Copy config.ini to all nodes
#vi /etc/cloudera-scm-agent/config.ini
#  server_host=ccycloud-1.feng.root.hwx.site
#  use_tls=1
#  verify_cert_file=/opt/cloudera/security/pki/agent.crt
#  client_key_file=/opt/cloudera/security/pki/agent.pem
#  client_keypw_file=/etc/cloudera-scm-agent/agentkey.pw
#  client_cert_file=/opt/cloudera/security/pki/agent.crt
scp /etc/cloudera-scm-agent/config.ini root@ccycloud-2.feng.root.hwx.site:/etc/cloudera-scm-agent/ 
scp /etc/cloudera-scm-agent/config.ini root@ccycloud-3.feng.root.hwx.site:/etc/cloudera-scm-agent/
scp /etc/cloudera-scm-agent/config.ini root@ccycloud-4.feng.root.hwx.site:/etc/cloudera-scm-agent/
scp /etc/cloudera-scm-agent/config.ini root@ccycloud-5.feng.root.hwx.site:/etc/cloudera-scm-agent/

ln -s /opt/cloudera/security/pki/$(hostname -f).jks /opt/cloudera/security/pki/server.jks

##################################################################################
# Part10: Encryption-CM
# Note: The following script run on ALL NODES !!!
##################################################################################

mkdir -p /opt/cloudera/security/pki/

export jkspassword=cloudera
echo $jkspassword > passwd
echo $jkspassword >> passwd

keytool -genkeypair -alias $(hostname -f) -keyalg RSA -keystore /opt/cloudera/security/pki/$(hostname -f).jks -keysize 2048 -dname "CN=$(hostname -f)" -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera < passwd
keytool -certreq -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).csr -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera
openssl x509 -req -CA /opt/cloudera/security/pki/rootCA.crt -CAkey /opt/cloudera/security/pki/rootCA.key -CAcreateserial -days 500 -sha256 -in /opt/cloudera/security/pki/$(hostname -f).csr -out /opt/cloudera/security/pki/$(hostname -f).crt
cat /opt/cloudera/security/pki/rootCA.crt >> /opt/cloudera/security/pki/$(hostname -f).crt
echo "yes" | keytool -importcert -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).crt  -storepass cloudera
keytool -importkeystore -srckeystore /opt/cloudera/security/pki/$(hostname -f).jks -destkeystore /opt/cloudera/security/pki/$(hostname -f).p12 -srcalias $(hostname -f) -srcstoretype jks -deststoretype pkcs12  -storepass cloudera < passwd
openssl pkcs12 -in /opt/cloudera/security/pki/$(hostname -f).p12 -out /opt/cloudera/security/pki/$(hostname -f).pem -password pass:cloudera -passin pass:cloudera -passout pass:cloudera

ln -s /opt/cloudera/security/pki/$(hostname -f).pem /opt/cloudera/security/pki/agent.pem
ln -s /opt/cloudera/security/pki/$(hostname -f).crt /opt/cloudera/security/pki/agent.crt
echo $jkspassword > /etc/cloudera-scm-agent/agentkey.pw
chown root:root /etc/cloudera-scm-agent/agentkey.pw
chmod 440 /etc/cloudera-scm-agent/agentkey.pw
chmod 444 /opt/cloudera/security/pki/*
chmod 400 /opt/cloudera/security/pki/rootCA.*

keytool -list -keystore /opt/cloudera/security/pki/keystore.jks < passwd
keytool -list -keystore /opt/cloudera/security/pki/truststore.jks < passwd
rm -f passwd

systemctl restart cloudera-scm-server
systemctl restart cloudera-scm-agent


