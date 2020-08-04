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