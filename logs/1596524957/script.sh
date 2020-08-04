# Define global variables here
export USER=etl_user
export REALM=FENG.COM
export HOSTNAME=feng-

## On ALL nodes

# Setup cloudera manager repo
echo "[cloudera-manager]
name=Cloudera Manager 7.1.1
baseurl=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/
gpgkey=https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera
gpgcheck=1
enabled=1
autorefresh=0
type=rpm-md" >> /etc/yum.repos.d/cloudera-manager-7_1_1.repo
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
mkdir -p /data/kudu/wal 
chmod 755 /data/kudu/wal
chown kudu:kudu /data/kudu/wal

mkdir -p /data/kudu/data 
chmod 755 /data/kudu/data
chown kudu:kudu /data/kudu/data
