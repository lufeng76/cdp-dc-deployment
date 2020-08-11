yum -y install postgresql-jdbc*
cp /usr/share/java/postgresql-jdbc.jar /usr/share/java/postgresql-connector-java.jar
chmod 644 /usr/share/java/postgresql-connector-java.jar
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install https://yum.postgresql.org/10/redhat/rhel-7-x86_64/python3-psycopg2-2.8.5-1.rhel7.x86_64.rpm
yum -y install postgresql10