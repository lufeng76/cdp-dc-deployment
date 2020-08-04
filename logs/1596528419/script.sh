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